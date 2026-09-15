<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lupa Password - SIMHPSK</title>
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

        .field input {
            width: 100%;
            padding: 12px 14px;
            border: 1.5px solid #e5e7eb;
            border-radius: 10px;
            font-size: 15px;
            font-family: 'Inter', sans-serif;
            color: #111827;
            background: #f9fafb;
            transition: border-color 0.2s, box-shadow 0.2s;
            outline: none;
        }

        .field input:focus {
            border-color: #27AE60;
            box-shadow: 0 0 0 3px rgba(39, 174, 96, 0.12);
            background: #fff;
        }

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
            <h1>Lupa Password</h1>
            <p>Masukkan email Anda untuk menerima link reset password</p>
        </div>

        <div class="card-body">
            @if (session('status'))
                <div class="alert-success">
                    {{ session('status') }}
                </div>
            @endif

            @if ($errors->any())
                <div class="alert-error">
                    <ul>
                        @foreach ($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <form method="POST" action="{{ route('password.email') }}">
                @csrf

                <div class="field">
                    <label for="email">Email</label>
                    <input id="email" type="email" name="email" value="{{ old('email') }}" placeholder="contoh@email.com" required autofocus>
                </div>

                <button type="submit" class="btn-submit">✉️ Kirim Link Reset Password</button>
            </form>

            <div class="footer-link">
                <p>Sudah ingat password? <a href="{{ route('login') }}">Login</a></p>
            </div>
        </div>
    </div>
</body>
</html>
