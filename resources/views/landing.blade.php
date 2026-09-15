<!DOCTYPE html>
<html lang="id" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SIMHPSK - Pencatatan Pertanian</title>
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Nunito:wght@700;900&display=swap" rel="stylesheet">
    <link rel="icon" type="image/jpeg" href="{{ asset('images/logo.jpg') }}">
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Plus Jakarta Sans', 'sans-serif'],
                        heading: ['Nunito', 'sans-serif'],
                    },
                    colors: {
                        primary: '#2d6a4f',
                        'primary-dark': '#1b4332',
                        secondary: '#40916c',
                        surface: '#f2ede3', // Matches Flutter 0xFFF2EDE3
                        darkbg: '#1E3A2A' // Matches Flutter How It Works
                    }
                }
            }
        }
    </script>
    <style>
        body {
            background-color: #f8faf5;
            overflow-x: hidden;
        }
        
        /* Background Blurs */
        .blur-circle {
            position: absolute;
            border-radius: 50%;
            filter: blur(100px);
            z-index: -1;
            opacity: 0.6;
        }
        
        .blur-green {
            background-color: #a3b18a;
            width: 800px;
            height: 800px;
            top: -100px;
            left: -200px;
        }

        .blur-yellow {
            background-color: #e9c46a;
            width: 700px;
            height: 700px;
            bottom: -150px;
            right: -150px;
        }
        
        .underline-doodle {
            position: relative;
            display: inline-block;
        }
        .underline-doodle::after {
            content: '';
            position: absolute;
            left: 0;
            bottom: -2px;
            width: 100%;
            height: 8px;
            background: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 10" preserveAspectRatio="none"><path d="M0 5 Q 50 10 100 5" stroke="%2340916c" stroke-width="3" fill="none"/></svg>') no-repeat center;
            background-size: 100% 100%;
        }

        /* Float animation */
        @keyframes float {
            0% { transform: translateY(0px); }
            50% { transform: translateY(-20px); }
            100% { transform: translateY(0px); }
        }
        .animate-float {
            animation: float 6s ease-in-out infinite;
        }

        /* Heartbeat animation for button */
        @keyframes heartbeat {
            0%, 100% { transform: scale(1); }
            10%, 30% { transform: scale(1.05); }
            20% { transform: scale(1.02); }
        }
        .animate-heartbeat {
            animation: heartbeat 2s infinite;
        }

        /* Flowing Blob animation */
        @keyframes blob {
            0% { transform: translate(0px, 0px) scale(1) rotate(0deg); }
            33% { transform: translate(15vw, -15vh) scale(1.2) rotate(90deg); }
            66% { transform: translate(-10vw, 15vh) scale(0.8) rotate(180deg); }
            100% { transform: translate(0px, 0px) scale(1) rotate(270deg); }
        }
        .animate-blob {
            animation: blob 20s infinite alternate ease-in-out;
        }
        .animation-delay-2000 {
            animation-delay: 2s;
        }
        .animation-delay-4000 {
            animation-delay: 4s;
        }

        .potato-particle {
            will-change: transform, opacity, left, top;
            pointer-events: none;
            z-index: 9999;
            background-size: contain;
            background-repeat: no-repeat;
            background-position: center;
        }

    </style>
</head>
<body class="font-sans antialiased text-gray-800 flex flex-col relative min-h-screen" style="background-image: url('{{ asset('images/bg-pertanian.jpg') }}'); background-size: cover; background-position: center; background-attachment: fixed;">

    <div id="potato-explosion-container" class="pointer-events-none fixed inset-0 overflow-hidden z-50"></div>

    <!-- Background Overlay for readability -->
    <div class="fixed inset-0 z-[-2] bg-black/50"></div>

    <!-- Background Animated Elements -->
    <div class="fixed inset-0 z-[-1] w-full h-full overflow-hidden pointer-events-none">
        <!-- Interactive Cursor Blob (Biscotti) -->
        <div id="cursor-blob" class="absolute top-0 left-0 w-[40vw] h-[40vw] -ml-[20vw] -mt-[20vw] rounded-full bg-[#e3cba8]/20 filter blur-[100px] transition-transform duration-[800ms] ease-out will-change-transform"></div>
        
        <!-- Flowing Blobs -->
        <div class="absolute top-[-10%] left-[-10%] w-[50vw] h-[50vw] rounded-full bg-[#cbb29b]/20 filter blur-[100px] animate-blob"></div>
        <div class="absolute top-[20%] right-[-10%] w-[45vw] h-[45vw] rounded-full bg-[#8d5d47]/40 filter blur-[100px] animate-blob animation-delay-2000"></div>
        <div class="absolute bottom-[-20%] left-[20%] w-[60vw] h-[60vw] rounded-full bg-[#e3cba8]/20 filter blur-[100px] animate-blob animation-delay-4000"></div>
    </div>

    <!-- Navbar -->
    <nav class="sticky top-0 backdrop-blur-md bg-[#A39987]/90 border-b border-[#5D3A2F]/50 flex justify-between items-center px-8 py-4 mx-auto w-full z-50">
        <div class="max-w-7xl mx-auto w-full flex justify-between items-center">
            <!-- Logo -->
            <div class="flex items-center gap-3">
                <div class="w-12 h-12 rounded-xl overflow-hidden shadow-inner shadow-black/30 bg-white ring-1 ring-white/20">
                    <img src="{{ asset('images/logo.jpg') }}" alt="Logo SIMHPSK" class="w-full h-full object-cover">
                </div>
                <div>
                    <h1 class="text-xl font-bold leading-none text-white tracking-tight">SIMHPSK</h1>
                    <p class="text-[10px] text-white/70 font-semibold tracking-wider uppercase mt-1">Pencatatan Pertanian</p>
                </div>
            </div>

            <!-- Links -->
            <div class="hidden md:flex items-center gap-8 text-sm font-semibold text-white/90">
                <a href="#fitur" class="nav-link hover:text-white transition rounded-full px-3 py-2 text-white/90">Fitur</a>
                <a href="#statistik" class="nav-link hover:text-white transition rounded-full px-3 py-2 text-white/90">Statistik</a>
                <a href="#cara-kerja" class="nav-link hover:text-white transition rounded-full px-3 py-2 text-white/90">Cara Kerja</a>
                <a href="#ulasan" class="nav-link hover:text-white transition rounded-full px-3 py-2 text-white/90">Ulasan</a>
                <a href="#tim" class="nav-link hover:text-white transition rounded-full px-3 py-2 text-white/90">Tim</a>
            </div>

            <!-- Actions -->
            <div class="flex items-center gap-4">
                <button onclick="handleAppRouting(event)" class="download-trigger text-sm font-bold text-white bg-primary hover:bg-primary-dark transition px-6 py-2.5 rounded-xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[6px_6px_0px_0px_#391F18] hover:-translate-y-1 flex items-center gap-2 animate-heartbeat">
                    Download Aplikasi
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd" />
                    </svg>
                </button>
            </div>
        </div>
    </nav>

    <!-- 1. HERO SECTION -->
    <section class="flex flex-col items-center justify-center text-center px-4 z-10 pt-20 pb-24">
        <!-- Badge -->
        <div class="inline-flex items-center gap-2 bg-green-100/80 backdrop-blur-sm border border-green-200 text-primary-dark px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-wide mb-8 shadow-sm">
            <div class="w-2 h-2 bg-secondary rounded-full animate-pulse"></div>
            Platform Manajemen Pertanian Digital #1
        </div>

        <!-- Headline -->
        <h2 class="text-5xl md:text-6xl font-heading font-extrabold text-[#e3cba8] max-w-4xl leading-[1.15] tracking-tight">
            Kelola Panen dan Stok Kentang dengan
            <span id="animated-word" class="text-white transition-all duration-500 ease-in-out inline-block">Cerdas</span>
        </h2>

        <!-- Subheadline -->
        <p class="mt-8 text-white/80 font-medium max-w-2xl text-lg leading-relaxed">
            Sistem Informasi Manajemen Panen dan Stok Kentang yang membantu Anda mengelola usaha pertanian dengan lebih efisien dan menguntungkan.
        </p>

        <!-- CTA Buttons -->
        <div class="flex flex-col sm:flex-row items-center gap-4 mt-12">
            <button onclick="handleAppRouting(event)" class="download-trigger text-base font-bold text-gray-900 bg-[#e3cba8] hover:bg-white transition-all px-8 py-3.5 rounded-xl border-2 border-[#391F18] shadow-[6px_6px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] w-full sm:w-auto justify-center hover:-translate-y-1 animate-heartbeat flex items-center gap-3">
                Download Aplikasi Android
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
            </button>
        </div>

        <!-- Features Checklist -->
        <div class="flex flex-wrap items-center justify-center gap-6 mt-8 text-sm font-medium text-[#e3cba8]">
            <div class="flex items-center gap-2"><span class="text-green-400"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-5"><path fill-rule="evenodd" d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12Zm13.36-1.814a.75.75 0 1 0-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 0 0-1.06 1.06l2.25 2.25a.75.75 0 0 0 1.14-.094l3.75-5.25Z" clip-rule="evenodd" /></svg></span> Mudah digunakan</div>
            <div class="flex items-center gap-2"><span class="text-blue-400"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-5"><path fill-rule="evenodd" d="M9.315 1.5a.75.75 0 0 0-.44.132l-7.125 5.25a.75.75 0 0 0-.25.809l2.7 8.358A.75.75 0 0 0 4.896 16.5H19.1a.75.75 0 0 0 .696-.451l2.7-8.358a.75.75 0 0 0-.25-.809l-7.125-5.25a.75.75 0 0 0-.44-.132H9.315ZM10.5 5.25v2.25H7.5V9h3v2.25H7.5v1.5h3v2.25h1.5v-2.25h3v-1.5h-3V9h3V7.5h-3V5.25h-1.5Z" clip-rule="evenodd" /></svg></span> Gratis selamanya</div>
            <div class="flex items-center gap-2"><span class="text-yellow-400"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-5"><path fill-rule="evenodd" d="M12 1.5a5.25 5.25 0 0 0-5.25 5.25v3a3 3 0 0 0-3 3v6.75a3 3 0 0 0 3 3h10.5a3 3 0 0 0 3-3v-6.75a3 3 0 0 0-3-3v-3c0-2.9-2.35-5.25-5.25-5.25Zm3.75 8.25v-3a3.75 3.75 0 1 0-7.5 0v3h7.5Z" clip-rule="evenodd" /></svg></span> Data aman & terenkripsi</div>
        </div>

        <!-- Mockup Dashboard -->
        <div class="mt-20 w-full max-w-4xl bg-white rounded-2xl shadow-[12px_12px_0px_0px_#391F18] border-2 border-[#391F18] p-4 md:p-8 animate-float relative z-10">
            <!-- Window controls -->
            <div class="flex items-center gap-2 mb-6">
                <div class="w-3 h-3 rounded-full bg-red-500"></div>
                <div class="w-3 h-3 rounded-full bg-yellow-500"></div>
                <div class="w-3 h-3 rounded-full bg-green-500"></div>
            </div>
            
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
                <div class="bg-yellow-50 p-4 rounded-xl border border-yellow-100">
                    <p class="text-yellow-800 text-xs font-bold mb-1">Stok Gudang</p>
                    <p class="text-yellow-600 text-xl font-black">4.500 kg</p>
                </div>
                <div class="bg-green-50 p-4 rounded-xl border border-green-100">
                    <p class="text-green-800 text-xs font-bold mb-1">Total Panen</p>
                    <p class="text-green-600 text-xl font-black">12.400 kg</p>
                </div>
                <div class="bg-blue-50 p-4 rounded-xl border border-blue-100">
                    <p class="text-blue-800 text-xs font-bold mb-1">Pendapatan</p>
                    <p class="text-blue-600 text-xl font-black">Rp 74,4 jt</p>
                </div>
                <div class="bg-teal-50 p-4 rounded-xl border border-teal-100">
                    <p class="text-teal-800 text-xs font-bold mb-1">Est. Untung</p>
                    <p class="text-teal-600 text-xl font-black">Rp 28,6 jt</p>
                </div>
            </div>

            <!-- Chart mockup -->
            <div class="h-48 border border-gray-100 rounded-xl bg-gray-50 p-4 flex items-end gap-4 justify-between">
                <div class="w-full bg-green-200 rounded-t-sm" style="height: 60%"></div>
                <div class="w-full bg-blue-200 rounded-t-sm" style="height: 80%"></div>
                <div class="w-full bg-green-200 rounded-t-sm" style="height: 45%"></div>
                <div class="w-full bg-blue-200 rounded-t-sm" style="height: 90%"></div>
                <div class="w-full bg-green-200 rounded-t-sm" style="height: 70%"></div>
                <div class="w-full bg-blue-200 rounded-t-sm" style="height: 100%"></div>
            </div>
        </div>
    </section>

    <!-- 2. STATS SECTION -->
    <section id="statistik" class="w-full bg-transparent text-white py-16 px-4 relative overflow-hidden">
        <div class="max-w-6xl mx-auto grid grid-cols-2 md:grid-cols-4 gap-8 relative z-10">
            <div class="text-center">
                <p class="text-4xl font-black text-[#e3cba8] mb-2">1200<span class="text-2xl text-white">+</span></p>
                <p class="text-sm font-bold uppercase tracking-wider text-white/80 opacity-80">Petani Aktif</p>
            </div>
            <div class="text-center">
                <p class="text-4xl font-black text-[#e3cba8] mb-2">98<span class="text-2xl text-white">%</span></p>
                <p class="text-sm font-bold uppercase tracking-wider text-white/80 opacity-80">Kepuasan Pengguna</p>
            </div>
            <div class="text-center">
                <p class="text-4xl font-black text-[#e3cba8] mb-2">45<span class="text-2xl text-white"> jt</span></p>
                <p class="text-sm font-bold uppercase tracking-wider text-white/80 opacity-80">Transaksi Tercatat</p>
            </div>
            <div class="text-center">
                <p class="text-4xl font-black text-[#e3cba8] mb-2">100<span class="text-2xl text-white">%</span></p>
                <p class="text-sm font-bold uppercase tracking-wider text-white/80 opacity-80">Aman & Terenkripsi</p>
            </div>
        </div>
    </section>

    <!-- 3. FEATURES SECTION -->
    <section id="fitur" class="w-full bg-transparent py-24 px-4">
        <div class="max-w-6xl mx-auto">
            <div class="text-center mb-16">
                <div class="inline-flex items-center gap-1.5 px-4 py-1.5 bg-green-100 border border-green-200 rounded-full text-xs font-bold text-primary-dark uppercase tracking-wide mb-4">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4 text-yellow-500"><path fill-rule="evenodd" d="M9 4.5a.75.75 0 0 1 .721.544l.813 2.846a3.75 3.75 0 0 0 2.576 2.576l2.846.813a.75.75 0 0 1 0 1.442l-2.846.813a3.75 3.75 0 0 0-2.576 2.576l-.813 2.846a.75.75 0 0 1-1.442 0l-.813-2.846a3.75 3.75 0 0 0-2.576-2.576l-2.846-.813a.75.75 0 0 1 0-1.442l2.846-.813A3.75 3.75 0 0 0 7.466 7.89l.813-2.846A.75.75 0 0 1 9 4.5ZM18 1.5a.75.75 0 0 1 .728.568l.258 1.036c.236.94.97 1.674 1.91 1.91l1.036.258a.75.75 0 0 1 0 1.456l-1.036.258c-.94.236-1.674.97-1.91 1.91l-.258 1.036a.75.75 0 0 1-1.456 0l-.258-1.036a2.625 2.625 0 0 0-1.91-1.91l-1.036-.258a.75.75 0 0 1 0-1.456l1.036-.258a2.625 2.625 0 0 0 1.91-1.91l.258-1.036A.75.75 0 0 1 18 1.5ZM16.5 15a.75.75 0 0 1 .712.513l.394 1.183c.15.447.5.799.948.948l1.183.395a.75.75 0 0 1 0 1.422l-1.183.395c-.447.15-.799.5-.948.948l-.395 1.183a.75.75 0 0 1-1.422 0l-.395-1.183a1.5 1.5 0 0 0-.948-.948l-1.183-.395a.75.75 0 0 1 0-1.422l1.183-.395c.447-.15.799-.5.948-.948l.395-1.183A.75.75 0 0 1 16.5 15Z" clip-rule="evenodd" /></svg>
                    Fitur Unggulan
                </div>
                <h2 class="text-4xl font-heading font-black text-[#e3cba8]">Semua Yang Anda Butuhkan</h2>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <!-- Feature 1 -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-2 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M11.35 3.836c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 0 0 .75-.75 2.25 2.25 0 0 0-.1-.664m-5.8 0A2.251 2.251 0 0 1 13.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m8.9-4.414c.376.023.75.05 1.124.08 1.131.094 1.976 1.057 1.976 2.192V16.5A2.25 2.25 0 0 1 18 18.75h-2.25m-7.5-10.5H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V18.75m-7.5-10.5h6.375c.621 0 1.125.504 1.125 1.125v9.375m-8.25-3 1.5 1.5 3-3.75" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Pencatatan Panen</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Catat setiap hasil panen lengkap dengan foto, berat, dan keterangan blok kebun.</p>
                </div>
                <!-- Feature 2 -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-2 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                          <path stroke-linecap="round" stroke-linejoin="round" d="m21 7.5-9-5.25L3 7.5m18 0-9 5.25m9-5.25v9l-9 5.25M3 7.5l9 5.25M3 7.5v9l9 5.25m0-9v9" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Manajemen Stok</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Pantau stok gudang secara real-time dengan notifikasi batas minimum otomatis.</p>
                </div>
                <!-- Feature 3 -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-2 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18.75a60.07 60.07 0 0 1 15.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 0 1 3 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 0 0-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 0 1-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 0 0 3 15h-.75M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm3 0h.008v.008H18V10.5Zm-12 0h.008v.008H6V10.5Z" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Laporan Keuangan</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Hitung pendapatan, biaya produksi, dan estimasi untung-rugi per musim tanam.</p>
                </div>
                <!-- Feature 4 -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-2 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 3h1.386c.51 0 .955.343 1.087.835l.383 1.437M7.5 14.25a3 3 0 0 0-3 3h15.75m-12.75-3h11.218c1.121-2.3 2.1-4.684 2.924-7.138a60.114 60.114 0 0 0-16.536-1.84M7.5 14.25 5.106 5.272M6 20.25a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Zm12.75 0a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Manajemen Penjualan</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Kelola transaksi penjualan dan data pembeli dalam satu platform terpadu.</p>
                </div>
                <!-- Feature 5 -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-2 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Analitik & Grafik</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Visualisasi data panen dan penjualan dengan grafik interaktif yang mudah dipahami.</p>
                </div>
                <!-- Feature 6 -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-2 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M12 21v-8.25M15.75 21v-8.25M8.25 21v-8.25M3 9l9-6 9 6m-1.5 12V10.332A48.36 48.36 0 0 0 12 9.75c-2.551 0-5.056.2-7.5.582V21M3 21h18M12 6.75h.008v.008H12V6.75Z" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Musim Tanam</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Atur dan pantau setiap periode musim tanam dengan riwayat lengkap.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- 4. HOW IT WORKS SECTION -->
    <section id="cara-kerja" class="w-full bg-transparent py-24 px-4 text-white relative">
        <div class="max-w-4xl mx-auto">
            <div class="text-center mb-16">
                <div class="inline-block px-4 py-1.5 bg-[#e3cba8] border-2 border-[#391F18] shadow-[2px_2px_0px_0px_#391F18] rounded-full text-xs font-bold text-[#391F18] uppercase tracking-wide mb-4">
                    Cara Kerja
                </div>
                <h2 class="text-4xl font-heading font-black text-[#e3cba8]">Hanya 4 Langkah Mudah</h2>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-4 gap-8 relative">


                <div class="relative z-10 text-center">
                    <div class="w-20 h-20 mx-auto bg-[#e3cba8] border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] rounded-full flex items-center justify-center text-[#391F18] mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-8">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z" />
                        </svg>
                    </div>
                    <p class="text-[#e3cba8] font-black text-xl mb-1">01</p>
                    <h3 class="font-bold text-lg mb-2 text-white">Daftar & Masuk</h3>
                    <p class="text-white/70 font-medium text-sm">Buat akun gratis dalam hitungan menit.</p>
                </div>
                <div class="relative z-10 text-center">
                    <div class="w-20 h-20 mx-auto bg-[#e3cba8] border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] rounded-full flex items-center justify-center text-[#391F18] mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-8">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
                        </svg>
                    </div>
                    <p class="text-[#e3cba8] font-black text-xl mb-1">02</p>
                    <h3 class="font-bold text-lg mb-2 text-white">Atur Musim Tanam</h3>
                    <p class="text-white/70 font-medium text-sm">Tentukan periode dan blok kebun Anda.</p>
                </div>
                <div class="relative z-10 text-center">
                    <div class="w-20 h-20 mx-auto bg-[#e3cba8] border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] rounded-full flex items-center justify-center text-[#391F18] mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-8">
                          <path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" />
                        </svg>
                    </div>
                    <p class="text-[#e3cba8] font-black text-xl mb-1">03</p>
                    <h3 class="font-bold text-lg mb-2 text-white">Catat Aktivitas</h3>
                    <p class="text-white/70 font-medium text-sm">Rekam panen, transaksi, dan pengeluaran.</p>
                </div>
                <div class="relative z-10 text-center">
                    <div class="w-20 h-20 mx-auto bg-[#e3cba8] border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] rounded-full flex items-center justify-center text-[#391F18] mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-8">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18 9 11.25l4.306 4.306a11.95 11.95 0 0 1 5.814-5.518l2.74-1.22m0 0-5.94-2.281m5.94 2.28-2.28 5.941" />
                        </svg>
                    </div>
                    <p class="text-[#e3cba8] font-black text-xl mb-1">04</p>
                    <h3 class="font-bold text-lg mb-2 text-white">Analisis & Tumbuh</h3>
                    <p class="text-white/70 font-medium text-sm">Gunakan laporan untuk keputusan cerdas.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- 5. TESTIMONIALS SECTION -->
    <section id="ulasan" class="w-full bg-transparent py-24 px-4">
        <div class="max-w-6xl mx-auto">
            <div class="text-center mb-16">
                <div class="inline-flex items-center gap-1.5 px-4 py-1.5 bg-yellow-100 border border-yellow-200 rounded-full text-xs font-bold text-yellow-800 uppercase tracking-wide mb-4">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4 text-yellow-500"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                    Ulasan Pengguna
                </div>
                <h2 class="text-4xl font-heading font-black text-[#e3cba8]">Kata Mereka</h2>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:-translate-y-1 transition-all">
                    <div class="flex text-yellow-400 mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                    </div>
                    <p class="text-gray-600 italic text-sm mb-6 leading-relaxed">"Aplikasi ini luar biasa mudah digunakan! Sekarang saya bisa pantau stok dan untung-rugi dengan mudah dari HP."</p>
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-blue-600">
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-5"><path fill-rule="evenodd" d="M7.5 6a4.5 4.5 0 1 1 9 0 4.5 4.5 0 0 1-9 0ZM3.751 20.105a8.25 8.25 0 0 1 16.498 0 .75.75 0 0 1-.437.695A18.683 18.683 0 0 1 12 22.5c-2.786 0-5.433-.608-7.812-1.7a.75.75 0 0 1-.437-.695Z" clip-rule="evenodd" /></svg>
                        </div>
                        <div>
                            <p class="font-bold text-gray-800 text-sm">Pak Budi Santoso</p>
                            <p class="text-xs text-gray-500">Pangalengan, Jawa Barat</p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:-translate-y-1 transition-all">
                    <div class="flex text-yellow-400 mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                    </div>
                    <p class="text-gray-600 italic text-sm mb-6 leading-relaxed">"Sangat membantu untuk mencatat hasil panen. Tulisannya besar dan jelas, cocok untuk saya yang sudah tua."</p>
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 bg-pink-100 rounded-full flex items-center justify-center text-pink-600">
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-5"><path fill-rule="evenodd" d="M7.5 6a4.5 4.5 0 1 1 9 0 4.5 4.5 0 0 1-9 0ZM3.751 20.105a8.25 8.25 0 0 1 16.498 0 .75.75 0 0 1-.437.695A18.683 18.683 0 0 1 12 22.5c-2.786 0-5.433-.608-7.812-1.7a.75.75 0 0 1-.437-.695Z" clip-rule="evenodd" /></svg>
                        </div>
                        <div>
                            <p class="font-bold text-gray-800 text-sm">Bu Sari Dewi</p>
                            <p class="text-xs text-gray-500">Dieng, Jawa Tengah</p>
                        </div>
                    </div>
                </div>

                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:-translate-y-1 transition-all">
                    <div class="flex text-yellow-400 mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-4"><path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.006 5.404.434c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.434 2.082-5.005Z" clip-rule="evenodd" /></svg>
                    </div>
                    <p class="text-gray-600 italic text-sm mb-6 leading-relaxed">"Laporan keuangannya sangat detail. Saya jadi tahu persis berapa untung setiap musim panen."</p>
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center text-green-600">
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-5"><path fill-rule="evenodd" d="M7.5 6a4.5 4.5 0 1 1 9 0 4.5 4.5 0 0 1-9 0ZM3.751 20.105a8.25 8.25 0 0 1 16.498 0 .75.75 0 0 1-.437.695A18.683 18.683 0 0 1 12 22.5c-2.786 0-5.433-.608-7.812-1.7a.75.75 0 0 1-.437-.695Z" clip-rule="evenodd" /></svg>
                        </div>
                        <div>
                            <p class="font-bold text-gray-800 text-sm">Pak Bambang Susilo</p>
                            <p class="text-xs text-gray-500">Magelang</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- 6. TIM DEVELOPER SECTION -->
    <section id="tim" class="w-full bg-transparent py-24 px-4 text-white relative">
        <div class="max-w-6xl mx-auto">
            <!-- Header Section -->
            <div class="flex items-center gap-4 mb-4">
                <div class="w-12 h-[2px] bg-[#e3cba8]"></div>
                <p class="text-[#e3cba8] font-bold text-sm tracking-widest uppercase">// ANGGOTA.TIM</p>
            </div>
            
            <h2 class="text-5xl md:text-7xl font-heading font-black mb-6 tracking-tight">
                TIM <span class="text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 to-[#e3cba8] drop-shadow-[0_0_15px_rgba(251,191,36,0.3)]">DEVELOPER</span>
            </h2>
            
            <p class="text-white/70 max-w-xl text-lg mb-12">
                Lima spesialis yang berkolaborasi membangun produk digital berperforma tinggi.
            </p>
            
            <div class="w-full h-[1px] bg-[#e3cba8]/30 mb-20"></div>

            <div class="flex flex-col gap-32">
                <!-- Team Member 1 (Text Left, Image Right) -->
                <div class="flex flex-col md:flex-row items-center justify-between gap-12">
                    <div class="md:w-1/2">
                        <div class="flex items-center gap-3 mb-6">
                            <div class="bg-[#e3cba8] text-[#391F18] font-bold text-xs px-2 py-1 rounded">&lt; /&gt;</div>
                            <p class="text-[#e3cba8] font-bold text-sm tracking-widest uppercase">PROJECT MANAGER</p>
                        </div>
                        <h3 class="text-4xl md:text-5xl font-black text-white mb-6 leading-tight uppercase">NOSA PUTRA</h3>
                        <p class="text-white/70 text-lg leading-relaxed">
                            Bertanggung jawab atas koordinasi tim dan memastikan proyek berjalan lancar dan selesai tepat waktu dengan kualitas terbaik.
                        </p>
                    </div>
                    <div class="md:w-1/2 flex justify-center md:justify-end">
                        <div class="relative w-72 h-72 md:w-96 md:h-96 rounded-full p-2" style="background: linear-gradient(135deg, rgba(227,203,168,0.5) 0%, rgba(227,203,168,0.1) 100%);">
                            <div class="w-full h-full rounded-full overflow-hidden border-[4px] border-[#e3cba8]/50 bg-black">
                                <img src="{{ asset('images/nosa-putra.png') }}" alt="Nosa Putra" class="w-full h-full object-cover grayscale opacity-90 hover:grayscale-0 hover:opacity-100 transition duration-700">
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Team Member 2 (Image Left, Text Right) -->
                <div class="flex flex-col md:flex-row-reverse items-center justify-between gap-12">
                    <div class="md:w-1/2">
                        <div class="flex items-center gap-3 mb-6">
                            <div class="bg-[#e3cba8] text-[#391F18] font-bold text-xs px-2 py-1 rounded">&lt; /&gt;</div>
                        <p class="text-[#e3cba8] font-bold text-sm tracking-widest uppercase">FRONTEND DEVELOPER 2</p>
                        </div>
                        <h3 class="text-4xl md:text-5xl font-black text-white mb-6 leading-tight uppercase">NAUFAL FAUZAN AZMII</h3>
                        <p class="text-white/70 text-lg leading-relaxed">
                           Bertanggung jawab dalam merancang dan mengembangkan antarmuka pengguna (UI) website agar responsif, menarik, dan mudah digunakan. Mengimplementasikan desain ke dalam kode, memastikan kompatibilitas di berbagai perangkat, serta berkolaborasi dengan tim backend untuk mengintegrasikan API dan fungsionalitas aplikasi.
                        </p>
                    </div>
                    <div class="md:w-1/2 flex justify-center md:justify-start">
                        <div class="relative w-72 h-72 md:w-96 md:h-96 rounded-full p-2" style="background: linear-gradient(135deg, rgba(227,203,168,0.5) 0%, rgba(227,203,168,0.1) 100%);">
                            <div class="w-full h-full rounded-full overflow-hidden border-[4px] border-[#e3cba8]/50 bg-black">
                                <img src="{{ asset('images/naufal.jpg') }}" alt="Naufal Fauzan Azmi" class="w-full h-full object-cover grayscale opacity-90 hover:grayscale-0 hover:opacity-100 transition duration-700">
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Team Member 3 (Text Left, Image Right) -->
                <div class="flex flex-col md:flex-row items-center justify-between gap-12">
                    <div class="md:w-1/2">
                        <div class="flex items-center gap-3 mb-6">
                            <div class="bg-[#e3cba8] text-[#391F18] font-bold text-xs px-2 py-1 rounded">&lt; /&gt;</div>
                            <p class="text-[#e3cba8] font-bold text-sm tracking-widest uppercase">FRONTEND DEVELOPER 1</p>
                        </div>
                        <h3 class="text-4xl md:text-5xl font-black text-white mb-6 leading-tight uppercase">ANGGRAENI GHEA SAPUTRI</h3>
                        <p class="text-white/70 text-lg leading-relaxed">
                            Membantu Frontend Developer 2 dalam mengembangkan antarmuka aplikasi, mengimplementasikan desain ke dalam kode, serta memastikan tampilan dan fungsionalitas berjalan sesuai kebutuhan proyek.
                        </p>
                    </div>
                    <div class="md:w-1/2 flex justify-center md:justify-end">
                        <div class="relative w-72 h-72 md:w-96 md:h-96 rounded-full p-2" style="background: linear-gradient(135deg, rgba(227,203,168,0.5) 0%, rgba(227,203,168,0.1) 100%);">
                            <div class="w-full h-full rounded-full overflow-hidden border-[4px] border-[#e3cba8]/50 bg-black">
                                <img src="{{ asset('images/ghea.jpg') }}" alt="Anggraeni Ghea Saputri" class="w-full h-full object-cover grayscale opacity-90 hover:grayscale-0 hover:opacity-100 transition duration-700">
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Team Member 4 (Image Left, Text Right) -->
                <div class="flex flex-col md:flex-row-reverse items-center justify-between gap-12">
                    <div class="md:w-1/2">
                        <div class="flex items-center gap-3 mb-6">
                            <div class="bg-[#e3cba8] text-[#391F18] font-bold text-xs px-2 py-1 rounded">&lt; /&gt;</div>
                            <p class="text-[#e3cba8] font-bold text-sm tracking-widest uppercase">BACKEND DEVELOPER</p>
                        </div>
                        <h3 class="text-4xl md:text-5xl font-black text-white mb-6 leading-tight uppercase">ADI MAULANA</h3>
                        <p class="text-white/70 text-lg leading-relaxed">
                           Bertanggung jawab dalam mengembangkan logika sistem, mengelola database, membuat serta mengintegrasikan API, dan memastikan seluruh proses backend berjalan dengan baik.
                        </p>
                    </div>
                    <div class="md:w-1/2 flex justify-center md:justify-start">
                        <div class="relative w-72 h-72 md:w-96 md:h-96 rounded-full p-2" style="background: linear-gradient(135deg, rgba(227,203,168,0.5) 0%, rgba(227,203,168,0.1) 100%);">
                            <div class="w-full h-full rounded-full overflow-hidden border-[4px] border-[#e3cba8]/50 bg-black">
                                <img src="{{ asset('images/adi.jpg') }}" alt="Adi Maulana" class="w-full h-full object-cover grayscale opacity-90 hover:grayscale-0 hover:opacity-100 transition duration-700">
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Team Member 5 (Text Left, Image Right) -->
                <div class="flex flex-col md:flex-row items-center justify-between gap-12">
                    <div class="md:w-1/2">
                        <div class="flex items-center gap-3 mb-6">
                            <div class="bg-[#e3cba8] text-[#391F18] font-bold text-xs px-2 py-1 rounded">&lt; /&gt;</div>
                            <p class="text-[#e3cba8] font-bold text-sm tracking-widest uppercase">QA & TESTER</p>
                        </div>
                        <h3 class="text-4xl md:text-5xl font-black text-white mb-6 leading-tight uppercase">ALDY SOFYAN SUNANDAR</h3>
                        <p class="text-white/70 text-lg leading-relaxed">
                           Bertanggung jawab melakukan pengujian aplikasi, menyusun skenario dan test case, mengidentifikasi serta mendokumentasikan bug, serta memastikan aplikasi memenuhi standar kualitas sebelum digunakan.
                        </p>
                    </div>
                    <div class="md:w-1/2 flex justify-center md:justify-end">
                        <div class="relative w-72 h-72 md:w-96 md:h-96 rounded-full p-2" style="background: linear-gradient(135deg, rgba(227,203,168,0.5) 0%, rgba(227,203,168,0.1) 100%);">
                            <div class="w-full h-full rounded-full overflow-hidden border-[4px] border-[#e3cba8]/50 bg-black">
                                <img src="{{ asset('images/aldi.jpg') }}" alt="Aldy Sofyan Sunandar" class="w-full h-full object-cover grayscale opacity-90 hover:grayscale-0 hover:opacity-100 transition duration-700">
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
        </div>
    </section>

    <!-- 7. CTA SECTION -->
    <section class="w-full bg-transparent py-24 px-4">
        <div class="max-w-4xl mx-auto bg-[#895A42] rounded-3xl border-2 border-[#391F18] p-10 md:p-16 text-center text-white shadow-[12px_12px_0px_0px_#391F18] relative overflow-hidden">
            <!-- Decorative circle -->
            <div class="absolute top-[-50px] right-[-50px] w-64 h-64 bg-white/10 rounded-full blur-2xl"></div>
            <div class="absolute bottom-[-50px] left-[-50px] w-64 h-64 bg-[#e3cba8]/20 rounded-full blur-2xl"></div>
            
            <h2 class="text-4xl md:text-5xl font-heading font-black mb-6 relative z-10">Siap Mengelola Panen Anda?</h2>
            <p class="text-white/90 mb-10 max-w-2xl mx-auto relative z-10 font-medium">Unduh aplikasinya sekarang dan bergabung dengan ribuan petani lain yang sudah mengoptimalkan hasil panen mereka.</p>
            
            <button onclick="handleAppRouting()" class="relative z-10 text-[#391F18] font-bold bg-[#e3cba8] hover:bg-white transition px-10 py-4 rounded-xl border-2 border-[#391F18] shadow-[6px_6px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-1 text-lg flex items-center gap-2 mx-auto animate-heartbeat">
                Download Aplikasi Android
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
            </button>
            
            <div class="flex flex-wrap items-center justify-center gap-6 mt-8 text-sm font-medium text-[#e3cba8] relative z-10">
                <div class="flex items-center gap-2"><span>✓</span> Tanpa kartu kredit</div>
                <div class="flex items-center gap-2"><span>✓</span> Setup 5 menit</div>
                <div class="flex items-center gap-2"><span>✓</span> Support 7 hari</div>
            </div>
        </div>
    </section>

    <!-- FOOTER -->
    <footer class="backdrop-blur-md bg-[#A39987]/90 border-t border-[#5D3A2F]/50 py-12 px-4 text-white">
        <div class="max-w-6xl mx-auto flex flex-col md:flex-row justify-between items-center gap-6">
            <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-lg overflow-hidden bg-white ring-1 ring-white/10">
                    <img src="{{ asset('images/logo.jpg') }}" alt="SIMHPSK" class="w-full h-full object-cover">
                </div>
                <span class="font-bold text-white tracking-tight">SIMHPSK</span>
            </div>
            
            <div class="flex items-center gap-6 text-sm text-white/90 font-medium">
                <a href="#fitur" class="hover:text-white">Fitur</a>
                <a href="#cara-kerja" class="hover:text-white">Cara Kerja</a>
                <a href="#ulasan" class="hover:text-white">Ulasan</a>
                <a href="#tim" class="hover:text-white">Tim</a>
            </div>
            
            <div class="text-sm text-white/70">
                © 2026 SIMHPSK. All rights reserved.
            </div>
        </div>
    </footer>

    <!-- Script for Deep Linking & Animations -->
    <script>
        // Deep Linking
        function handleAppRouting(event) {
            triggerPotatoExplosion(event);

            var appScheme = "simhpsk://open";
            var downloadUrl = "/download/simhpsk.apk";

            window.location.href = appScheme;

            setTimeout(function() {
                window.location.href = downloadUrl;
            }, 5200);
        }

        function triggerPotatoExplosion(event) {
            const container = document.getElementById('potato-explosion-container');
            if (!container) return;

            const explosionEmoji = '💥';

            const targetButton = event?.currentTarget || event?.target.closest('button');
            const buttonRect = targetButton?.getBoundingClientRect();
            const originX = buttonRect ? buttonRect.left + buttonRect.width / 2 : window.innerWidth / 2;
            const originY = buttonRect ? buttonRect.top + buttonRect.height / 2 : window.innerHeight / 2;

            const footer = document.querySelector('footer');
            const footerRect = footer ? footer.getBoundingClientRect() : { left: window.innerWidth / 2, top: window.innerHeight, width: 0, height: 0 };
            const count = 8;

            for (let i = 0; i < count; i++) {
                const particle = document.createElement('div');
                particle.className = 'potato-particle';
                const size = Math.floor(Math.random() * 18) + 36;
                particle.style.width = `${size}px`;
                particle.style.height = `${size}px`;
                particle.style.position = 'fixed';
                particle.style.left = `${originX}px`;
                particle.style.top = `${originY}px`;
                particle.style.borderRadius = '18%';
                particle.style.backgroundColor = 'transparent';
                particle.style.boxShadow = 'none';
                particle.style.opacity = '0';
                particle.style.fontSize = `${size}px`;
                particle.style.display = 'flex';
                particle.style.alignItems = 'center';
                particle.style.justifyContent = 'center';
                particle.style.textAlign = 'center';
                particle.style.transform = 'translate(-50%, -50%) scale(0.8) rotate(0deg)';
                particle.style.transition = 'transform 0.6s ease-out, opacity 0.2s ease, left 2s ease-in, top 2s ease-in';
                particle.textContent = explosionEmoji;
                container.appendChild(particle);

                const angle = Math.random() * Math.PI * 2;
                const distance = 200 + Math.random() * 90;
                const burstX = Math.cos(angle) * distance;
                const burstY = Math.sin(angle) * distance * -1;
                const rotate = Math.random() * 720;
                const driftX = Math.random() * 40 - 20;

                requestAnimationFrame(() => {
                    particle.style.opacity = '1';
                    particle.style.transform = `translate(calc(-50% + ${burstX}px), calc(-50% + ${burstY}px)) scale(1.2) rotate(${rotate}deg)`;
                });

                const landingX = originX + burstX * 0.7;
                const landingY = originY + burstY * 0.7;

                setTimeout(() => {
                    particle.style.transition = 'left 0.85s ease-out, top 0.85s ease-out, transform 0.85s ease-out';
                    particle.style.left = `${landingX}px`;
                    particle.style.top = `${landingY}px`;
                    particle.style.transform = `translate(-50%, -50%) rotate(${rotate + 480}deg) scale(1.35)`;
                }, 450 + i * 40);

                setTimeout(() => {
                    particle.style.transition = 'opacity 0.9s ease-out';
                    particle.style.opacity = '0';
                }, 1800 + i * 40);

                setTimeout(() => {
                    particle.remove();
                }, 2400 + i * 40);
            }
        }

        // Scroll Animations (FadeSlideOnScroll equivalent)
        document.addEventListener('DOMContentLoaded', function() {
            const observerOptions = {
                root: null,
                rootMargin: '0px',
                threshold: 0.15
            };

            const observer = new IntersectionObserver((entries, observer) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('opacity-100', 'translate-y-0');
                        entry.target.classList.remove('opacity-0', 'translate-y-8');
                        observer.unobserve(entry.target);
                    }
                });
            }, observerOptions);

            // Select all sections and feature cards to animate
            const animatedElements = document.querySelectorAll('section > div, .grid > div');
            animatedElements.forEach(el => {
                // Add initial state classes
                el.classList.add('transition-all', 'duration-1000', 'opacity-0', 'translate-y-8');
                observer.observe(el);
            });

            // Animated Headline Word
            const words = ["Cerdas", "Terintegrasi", "Mudah", "Efisien"];
            let wordIndex = 0;
            const animatedWordElement = document.getElementById("animated-word");
            
            if (animatedWordElement) {
                setInterval(() => {
                    // Fade out and move down slightly
                    animatedWordElement.style.opacity = '0';
                    animatedWordElement.style.transform = 'translateY(10px)';
                    
                    setTimeout(() => {
                        // Change text
                        wordIndex = (wordIndex + 1) % words.length;
                        animatedWordElement.textContent = words[wordIndex];
                        
                        // Fade back in
                        animatedWordElement.style.opacity = '1';
                        animatedWordElement.style.transform = 'translateY(0)';
                    }, 500); // matches the 500ms duration of the transition
                }, 2000);
            }

            // Cursor Blob Follower
            const cursorBlob = document.getElementById('cursor-blob');
            if (cursorBlob) {
                // Set initial position out of view or center
                cursorBlob.style.transform = `translate(50vw, 50vh)`;
                
                document.addEventListener('mousemove', (e) => {
                    // Use requestAnimationFrame for smoother performance if needed, 
                    // but CSS transition-transform makes it smooth enough automatically
                    cursorBlob.style.transform = `translate(${e.clientX}px, ${e.clientY}px)`;
                });
            }

            // Navigation active click effect and reset on scroll
            const navLinks = document.querySelectorAll('.nav-link');
            const activeLinkClasses = ['bg-[#5D3A2F]/90', 'text-white', 'animate-bounce'];
            let ignoreScrollReset = false;
            let scrollTimer;
            let scrollIgnoreTimer;

            function clearNavActive() {
                navLinks.forEach(link => {
                    link.classList.remove(...activeLinkClasses);
                    if (!link.classList.contains('text-white/90')) {
                        link.classList.add('text-white/90');
                    }
                });
            }

            function setActiveLink(link) {
                clearNavActive();
                link.classList.remove('text-white/90');
                link.classList.add(...activeLinkClasses);
                setTimeout(() => link.classList.remove('animate-bounce'), 600);
                ignoreScrollReset = true;
                clearTimeout(scrollIgnoreTimer);
                scrollIgnoreTimer = setTimeout(() => {
                    ignoreScrollReset = false;
                }, 700);
            }

            navLinks.forEach(link => {
                link.addEventListener('click', () => {
                    setActiveLink(link);
                });
            });

            window.addEventListener('scroll', () => {
                if (ignoreScrollReset) {
                    clearTimeout(scrollIgnoreTimer);
                    scrollIgnoreTimer = setTimeout(() => {
                        ignoreScrollReset = false;
                    }, 700);
                    return;
                }

                clearTimeout(scrollTimer);
                scrollTimer = setTimeout(() => {
                    clearNavActive();
                }, 120);
            });
        });
    </script>
</body>
</html>
