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
            $request->validate(['email' => 'required|email']);

            $status = Password::broker()->sendResetLink(
                $request->only('email')
            );

            if ($status == Password::RESET_LINK_SENT) {
                return $this->successResponse(null, __($status), 200);
            }

            return $this->errorResponse(__($status), 400);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function resetPasswordApi(Request $request)
    {
        try {
            $request->validate([
                'token' => 'required',
                'email' => 'required|email',
                'password' => 'required|min:8|confirmed',
            ], [
                'password.required' => 'Password baru harus diisi.',
                'password.min' => 'Password harus minimal 8 karakter.',
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

            if ($status == Password::PASSWORD_RESET) {
                return $this->successResponse(null, __($status), 200);
            }

            return $this->errorResponse(__($status), 400);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }
}
