<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Validation\ValidationException;

class PasswordResetController extends Controller
{
    use ApiResponseTrait;

    // ==========================================
    // WEB METHODS
    // ==========================================

    public function showForgotPasswordForm()
    {
        return view('auth.forgot-password');
    }

    public function sendResetLinkEmail(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $status = Password::broker()->sendResetLink(
            $request->only('email')
        );

        return $status == Password::RESET_LINK_SENT
            ? back()->with('status', __($status))
            : back()->withErrors(['email' => __($status)]);
    }

    public function showResetPasswordForm(Request $request, $token = null)
    {
        $token = $token ?? $request->query('token');

        if (! $token) {
            return redirect()->route('password.request')
                ->withErrors(['email' => 'Link reset password tidak valid. Silakan minta link baru.']);
        }

        return view('auth.reset-password', [
            'token' => $token,
            'email' => $request->query('email'),
        ]);
    }

    public function showResetSuccess()
    {
        return view('auth.reset-success');
    }

    public function resetPassword(Request $request)
    {
        $request->validate([
            'token'    => 'required',
            'email'    => 'required|email',
            'password' => 'required|min:8|confirmed',
        ], [
            'password.required'  => 'Password baru harus diisi.',
            'password.min'       => 'Password harus minimal 8 karakter.',
            'password.confirmed' => 'Password dan konfirmasi password tidak cocok.',
        ]);

        $status = Password::broker()->reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function ($user, $password) {
                $user->forceFill([
                    'password' => Hash::make($password)
                ])->setRememberToken(Str::random(60));
                $user->save();
                event(new PasswordReset($user));
            }
        );

        return $status == Password::PASSWORD_RESET
            ? redirect()->route('password.reset.success')
            : back()->withErrors(['email' => __($status)]);
    }

    // ==========================================
    // API METHODS
    // ==========================================

    public function sendResetLinkEmailApi(Request $request)
    {
        try {
            $request->validate(['email' => 'required|email'], [
                'email.required' => 'Email wajib diisi.',
                'email.email'    => 'Format email tidak valid.',
            ]);

            $token = null;
            $user = User::where('email', $request->email)->first();

            if ($user) {
                // Generate secure reset token via broker
                $token = Password::broker()->createToken($user);

                // Attempt to dispatch email notification; log any delivery errors gracefully
                try {
                    $user->sendPasswordResetNotification($token);
                } catch (\Throwable $e) {
                    \Log::error('Gagal mengirim email reset password: ' . $e->getMessage());
                }
            }

            // In local/testing environments with debug enabled, provide token strictly for automated testing/debugging
            $data = null;
            if (!app()->isProduction() && config('app.debug') && $token !== null) {
                $data = [
                    'email' => $request->email,
                    'token' => $token,
                ];
            }

            // Always return a generic response to prevent email enumeration
            return $this->successResponse(
                $data,
                'Jika email Anda terdaftar di sistem, instruksi reset password telah dikirimkan ke email Anda.',
                200
            );
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        } catch (\Throwable $e) {
            \Log::error('Error pada sendResetLinkEmailApi: ' . $e->getMessage());
            return $this->errorResponse('Terjadi kesalahan saat memproses permintaan.', 500);
        }
    }

    public function resetPasswordApi(Request $request)
    {
        try {
            $request->validate([
                'token'    => 'required',
                'email'    => 'required|email',
                'password' => 'required|min:8|confirmed',
            ], [
                'token.required'     => 'Token reset password wajib diisi.',
                'email.required'     => 'Email wajib diisi.',
                'email.email'        => 'Format email tidak valid.',
                'password.required'  => 'Password baru wajib diisi.',
                'password.min'       => 'Password baru minimal 8 karakter.',
                'password.confirmed' => 'Konfirmasi password tidak cocok.',
            ]);

            $status = Password::broker()->reset(
                $request->only('email', 'password', 'password_confirmation', 'token'),
                function ($user, $password) {
                    $user->forceFill([
                        'password' => Hash::make($password)
                    ])->setRememberToken(Str::random(60));

                    $user->save();

                    event(new PasswordReset($user));
                }
            );

            if ($status == Password::PASSWORD_RESET) {
                // Explicitly return success without issuing auto-login token
                return $this->successResponse(
                    null,
                    'Password Anda berhasil diperbarui. Silakan login menggunakan password baru.',
                    200
                );
            }

            $errorMessages = [
                Password::INVALID_TOKEN   => 'Token reset password tidak valid atau sudah kedaluwarsa.',
                Password::INVALID_USER    => 'Token reset password tidak valid atau sudah kedaluwarsa.',
                Password::RESET_THROTTLED => 'Terlalu banyak percobaan reset password. Harap tunggu beberapa saat lagi.',
            ];

            $message = $errorMessages[$status] ?? 'Gagal mereset password. Silakan minta token reset baru.';
            return $this->errorResponse($message, 400);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        } catch (\Throwable $e) {
            \Log::error('Error pada resetPasswordApi: ' . $e->getMessage());
            return $this->errorResponse('Terjadi kesalahan saat mereset password.', 500);
        }
    }
}
