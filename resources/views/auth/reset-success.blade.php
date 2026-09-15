<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password Berhasil - SIMHPSK</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Inter', sans-serif;
            min-height: 100vh;
            background: linear-gradient(135deg, #1A7A4A 0%, #27AE60 50%, #2ECC71 100%);
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
            text-align: center;
        }

        .card-header {
            background: linear-gradient(135deg, #1A7A4A, #27AE60);
            padding: 40px 32px 32px;
        }

        .card-header .success-icon {
            width: 80px;
            height: 80px;
            background: rgba(255,255,255,0.2);
            border-radius: 50%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 16px;
            animation: scaleIn 0.5s ease-out;
        }

        .card-header .success-icon svg {
            width: 44px;
            height: 44px;
        }

        .card-header h1 {
            color: #fff;
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 6px;
        }

        .card-body {
            padding: 40px 32px;
        }

        .success-message {
            font-size: 16px;
            color: #4b5563;
            line-height: 1.6;
            margin-bottom: 32px;
        }

        .btn-action {
            display: inline-block;
            width: 100%;
            padding: 14px 16px;
            background: linear-gradient(135deg, #1A7A4A, #27AE60);
            color: #fff;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            text-decoration: none;
            cursor: pointer;
            transition: opacity 0.2s, transform 0.1s;
        }

        .btn-action:hover { opacity: 0.92; transform: translateY(-1px); }
        .btn-action:active { transform: translateY(0); }

        @keyframes scaleIn {
            0% { transform: scale(0); opacity: 0; }
            80% { transform: scale(1.1); }
            100% { transform: scale(1); opacity: 1; }
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="card-header">
            <div class="success-icon">
                <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M9 16.17L4.83 12L3.41 13.41L9 19L21 7L19.59 5.59L9 16.17Z" fill="white"/>
                </svg>
            </div>
            <h1>Berhasil!</h1>
        </div>

        <div class="card-body">
            <p class="success-message">
                Password Anda telah berhasil diperbarui. Silakan kembali ke aplikasi mobile/web <strong>SIMHPSK</strong> untuk melakukan login dengan password baru Anda.
            </p>
            <a href="javascript:window.close();" class="btn-action">Tutup Halaman</a>
        </div>
    </div>
</body>
</html>
