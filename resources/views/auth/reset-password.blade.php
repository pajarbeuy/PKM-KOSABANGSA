<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password - SIMHPSK</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Inter', sans-serif;
            min-height: 100vh;
            background-color: #1A7A4A;
            background-image:
                linear-gradient(rgba(0, 0, 0, 0.28), rgba(0, 0, 0, 0.28)),
                url('{{ asset('images/background-login.png') }}');
            background-size: cover;
            background-position: center;
            background-repeat: no-repeat;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }

        .card {
            background: #fff;
            border-radius: 20px;
            box-shadow: 0 24px 60px rgba(0, 0, 0, 0.18);
            width: 100%;
            max-width: 420px;
            overflow: hidden;
        }

        .card-header {
            background: linear-gradient(135deg, #1A7A4A, #27AE60);
            padding: 32px 32px 28px;
            text-align: center;
        }

        .card-header .logo-icon {
            width: 64px;
            height: 64px;
            background: rgba(255,255,255,0.2);
            border-radius: 16px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 16px;
        }

        .card-header .logo-icon svg {
            width: 36px;
            height: 36px;
        }

        .card-header h1 {
            color: #fff;
            font-size: 22px;
            font-weight: 700;
            margin-bottom: 6px;
        }

        .card-header p {
            color: rgba(255,255,255,0.8);
            font-size: 13px;
        }

        .card-body {
            padding: 32px;
        }

        .alert-success {
            background: #ecfdf5;
            border: 1px solid #6ee7b7;
            color: #065f46;
            border-radius: 10px;
            padding: 12px 16px;
            font-size: 14px;
            margin-bottom: 20px;
        }

        .alert-error {
            background: #fef2f2;
            border: 1px solid #fca5a5;
            color: #991b1b;
            border-radius: 10px;
            padding: 12px 16px;
            font-size: 14px;
            margin-bottom: 20px;
        }

        .alert-error ul {
            margin: 0;
            padding-left: 18px;
        }

        .field {
            margin-bottom: 18px;
        }

        .field label {
            display: block;
            margin-bottom: 7px;
            font-size: 14px;
            font-weight: 600;
            color: #374151;
        }

        .input-wrap {
            position: relative;
        }

        .field input {
            width: 100%;
            padding: 12px 44px 12px 14px;
            border: 1.5px solid #e5e7eb;
            border-radius: 10px;
            font-size: 15px;
            font-family: 'Inter', sans-serif;
            color: #111827;
            background: #f9fafb;
            transition: border-color 0.2s, box-shadow 0.2s;
            outline: none;
        }

        .field input[type="email"] {
            background: #f0fdf4;
            color: #065f46;
            font-weight: 500;
            cursor: default;
        }

        .field input:focus {
            border-color: #27AE60;
            box-shadow: 0 0 0 3px rgba(39, 174, 96, 0.12);
            background: #fff;
        }

        .toggle-pw {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            cursor: pointer;
            color: #9ca3af;
            padding: 4px;
            display: flex;
            align-items: center;
        }

        .toggle-pw:hover { color: #27AE60; }

        .btn-submit {
            width: 100%;
            padding: 13px 16px;
            background: linear-gradient(135deg, #1A7A4A, #27AE60);
            color: #fff;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            font-family: 'Inter', sans-serif;
            cursor: pointer;
            transition: opacity 0.2s, transform 0.1s;
            margin-top: 4px;
        }

        .btn-submit:hover { opacity: 0.92; transform: translateY(-1px); }
        .btn-submit:active { transform: translateY(0); }

        .footer-link {
            text-align: center;
            margin-top: 22px;
            font-size: 14px;
            color: #6b7280;
        }

        .footer-link a {
            color: #1A7A4A;
            font-weight: 600;
            text-decoration: none;
        }

        .footer-link a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="card">
        <div class="card-header">
            <div class="logo-icon">
                <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" fill="white"/>
                </svg>
            </div>
            <h1>Reset Password</h1>
            <p>Buat password baru untuk akun Anda</p>
        </div>

        <div class="card-body">
            @if ($errors->any())
                <div class="alert-error">
                    <ul>
                        @foreach ($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <form method="POST" action="{{ route('password.update') }}">
                @csrf
                <input type="hidden" name="token" value="{{ $token }}">

                <div class="field">
                    <label for="email">Email</label>
                    <div class="input-wrap">
                        <input id="email" type="email" name="email"
                               value="{{ old('email', request('email')) }}"
                               readonly required autofocus>
                    </div>
                </div>

                <div class="field">
                    <label for="password">Password Baru</label>
                    <div class="input-wrap">
                        <input id="password" type="password" name="password"
                               placeholder="Minimal 8 karakter" required>
                        <button type="button" class="toggle-pw" onclick="togglePw('password', this)" aria-label="Lihat password">
                            <svg id="eye-password" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                            </svg>
                        </button>
                    </div>
                </div>

                <div class="field">
                    <label for="password_confirmation">Konfirmasi Password</label>
                    <div class="input-wrap">
                        <input id="password_confirmation" type="password" name="password_confirmation"
                               placeholder="Ulangi password baru" required>
                        <button type="button" class="toggle-pw" onclick="togglePw('password_confirmation', this)" aria-label="Lihat konfirmasi password">
                            <svg id="eye-password_confirmation" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                            </svg>
                        </button>
                    </div>
                </div>

                <button type="submit" class="btn-submit">🔒 Reset Password</button>
            </form>

            <div class="footer-link">
                <a href="{{ route('login') }}">← Kembali ke Login</a>
            </div>
        </div>
    </div>

    <script>
        function togglePw(fieldId, btn) {
            const input = document.getElementById(fieldId);
            const isText = input.type === 'text';
            input.type = isText ? 'password' : 'text';
            btn.querySelector('svg').innerHTML = isText
                ? '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>'
                : '<path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/>';
        }
    </script>
</body>
</html>
