<!DOCTYPE html>
<html lang="id" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SumberTani berbasis AI - Platform Manajemen & Hilirisasi Pertanian</title>
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Nunito:wght@700;900&display=swap" rel="stylesheet">
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
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
                        surface: '#f2ede3',
                        darkbg: '#1E3A2A'
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

        /* Float animation */
        @keyframes float {
            0% { transform: translateY(0px); }
            50% { transform: translateY(-16px); }
            100% { transform: translateY(0px); }
        }
        .animate-float {
            animation: float 6s ease-in-out infinite;
        }

        /* Heartbeat animation for button */
        @keyframes heartbeat {
            0%, 100% { transform: scale(1); }
            10%, 30% { transform: scale(1.04); }
            20% { transform: scale(1.01); }
        }
        .animate-heartbeat {
            animation: heartbeat 2.2s infinite;
        }

        /* Flowing Blob animation */
        @keyframes blob {
            0% { transform: translate(0px, 0px) scale(1) rotate(0deg); }
            33% { transform: translate(15vw, -15vh) scale(1.2) rotate(90deg); }
            66% { transform: translate(-20vw, 20vh) scale(0.8) rotate(180deg); }
            100% { transform: translate(0px, 0px) scale(1) rotate(360deg); }
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
<body class="relative min-h-screen text-gray-800 font-sans selection:bg-secondary selection:text-white">

    <div id="potato-explosion-container" class="pointer-events-none fixed inset-0 overflow-hidden z-50"></div>

    <!-- Dark Overlay Background Image -->
    <div class="fixed inset-0 z-[-2] bg-black/50"></div>

    <!-- Background Animated Elements -->
    <div class="fixed inset-0 z-[-1] w-full h-full overflow-hidden pointer-events-none">
        <!-- Interactive Cursor Blob -->
        <div id="cursor-blob" class="absolute top-0 left-0 w-[40vw] h-[40vw] -ml-[20vw] -mt-[20vw] rounded-full bg-[#e3cba8]/20 filter blur-[100px] transition-transform duration-[800ms] ease-out will-change-transform"></div>
        
        <!-- Flowing Blobs -->
        <div class="absolute top-[-10%] left-[-10%] w-[50vw] h-[50vw] rounded-full bg-[#cbb29b]/20 filter blur-[100px] animate-blob"></div>
        <div class="absolute top-[20%] right-[-10%] w-[45vw] h-[45vw] rounded-full bg-[#8d5d47]/40 filter blur-[100px] animate-blob animation-delay-2000"></div>
        <div class="absolute bottom-[-20%] left-[20%] w-[60vw] h-[60vw] rounded-full bg-[#e3cba8]/20 filter blur-[100px] animate-blob animation-delay-4000"></div>
    </div>

    <!-- 1. NAVBAR -->
    <nav class="sticky top-0 backdrop-blur-md bg-[#A39987]/90 border-b border-[#5D3A2F]/50 px-6 sm:px-8 py-3.5 mx-auto w-full z-50">
        <div class="max-w-7xl mx-auto w-full flex justify-between items-center">
            <!-- Logo -->
            <a href="#beranda" class="flex items-center gap-3 group">
                <div class="w-11 h-11 rounded-xl overflow-hidden shadow-inner shadow-black/30 bg-white ring-1 ring-white/20 p-1 flex items-center justify-center">
                    <img src="{{ asset('images/logo.png') }}" alt="Logo SumberTani" class="w-full h-full object-contain">
                </div>
                <div>
                    <h1 class="text-xl font-bold leading-none text-white tracking-tight group-hover:text-[#e3cba8] transition">SumberTani</h1>
                    <p class="text-[10px] text-white/75 font-semibold tracking-wider uppercase mt-1">Berbasis AI</p>
                </div>
            </a>

            <!-- Desktop Links -->
            <div class="hidden lg:flex items-center gap-6 text-sm font-semibold text-white/90">
                <a href="#beranda" class="nav-link hover:text-white transition rounded-full px-3 py-1.5 hover:bg-white/10">Beranda</a>
                <a href="#fitur" class="nav-link hover:text-white transition rounded-full px-3 py-1.5 hover:bg-white/10">Fitur</a>
                <a href="#hilirisasi" class="nav-link hover:text-white transition rounded-full px-3 py-1.5 hover:bg-white/10">Hilirisasi</a>
                <a href="{{ route('catalog') }}" class="nav-link hover:text-white transition rounded-full px-3.5 py-1.5 text-[#e3cba8] font-bold hover:bg-white/10 flex items-center gap-1.5 border border-[#e3cba8]/30">
                    <span>Katalog Produk</span>
                    <span class="text-[9px] bg-emerald-600 text-white px-2 py-0.5 rounded-full font-bold uppercase tracking-wider">Toko</span>
                </a>
                <a href="#cara-kerja" class="nav-link hover:text-white transition rounded-full px-3 py-1.5 hover:bg-white/10">Cara Kerja</a>
                <a href="#tentang" class="nav-link hover:text-white transition rounded-full px-3 py-1.5 hover:bg-white/10">Tentang SumberTani</a>
            </div>

            <!-- Action Button & Mobile Toggle -->
            <div class="flex items-center gap-3">
                <button onclick="handleAppRouting(event)" class="download-trigger text-sm font-bold text-white bg-primary hover:bg-primary-dark transition px-5 py-2.5 rounded-xl border-2 border-[#391F18] shadow-[3px_3px_0px_0px_#391F18] hover:shadow-[5px_5px_0px_0px_#391F18] hover:-translate-y-0.5 flex items-center gap-2">
                    <span>Masuk Aplikasi</span>
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M3 3a1 1 0 011 1v12a1 1 0 11-2 0V4a1 1 0 011-1zm7.707 3.293a1 1 0 010 1.414L9.414 9H17a1 1 0 110 2H9.414l1.293 1.293a1 1 0 01-1.414 1.414l-3-3a1 1 0 010-1.414l3-3a1 1 0 011.414 0z" clip-rule="evenodd" />
                    </svg>
                </button>

                <!-- Mobile Hamburger Toggle -->
                <button id="mobile-menu-button" class="lg:hidden p-2 rounded-xl text-white hover:bg-white/10 transition border border-white/20" aria-label="Buka Menu">
                    <svg id="hamburger-icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
                    </svg>
                    <svg id="close-icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6 hidden">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>
        </div>

        <!-- Mobile Menu Dropdown -->
        <div id="mobile-menu" class="hidden lg:hidden pt-4 pb-2 border-t border-white/10 mt-3 flex flex-col gap-2 text-sm font-semibold text-white/90">
            <a href="#beranda" class="mobile-nav-link px-3 py-2 rounded-lg hover:bg-white/10 transition">Beranda</a>
            <a href="#fitur" class="mobile-nav-link px-3 py-2 rounded-lg hover:bg-white/10 transition">Fitur</a>
            <a href="#hilirisasi" class="mobile-nav-link px-3 py-2 rounded-lg hover:bg-white/10 transition">Hilirisasi</a>
            <a href="{{ route('catalog') }}" class="mobile-nav-link px-3 py-2 rounded-lg text-[#e3cba8] font-bold hover:bg-white/10 transition flex items-center justify-between">
                <span>Katalog Produk</span>
                <span class="text-[9px] bg-emerald-600 text-white px-2 py-0.5 rounded-full font-bold uppercase">Buka Toko ➔</span>
            </a>
            <a href="#cara-kerja" class="mobile-nav-link px-3 py-2 rounded-lg hover:bg-white/10 transition">Cara Kerja</a>
            <a href="#tentang" class="mobile-nav-link px-3 py-2 rounded-lg hover:bg-white/10 transition">Tentang SumberTani</a>
        </div>
    </nav>

    <!-- 2. HERO SECTION -->
    <section id="beranda" class="flex flex-col items-center justify-center text-center px-4 z-10 pt-16 pb-24">
        <!-- Badge -->
        <div class="inline-flex items-center gap-2 bg-green-100/90 backdrop-blur-sm border border-green-200 text-primary-dark px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-wide mb-8 shadow-sm">
            <div class="w-2 h-2 bg-secondary rounded-full animate-pulse"></div>
            Platform Manajemen Pertanian & Hilirisasi Hasil Tani
        </div>

        <!-- Headline: Value proposition SumberTani -->
        <h2 class="text-4xl sm:text-5xl md:text-6xl font-heading font-extrabold text-[#e3cba8] max-w-4xl leading-[1.15] tracking-tight">
            Kelola Pertanian & Pasarkan Produk Olahan dengan
            <span id="animated-word" class="text-white transition-all duration-500 ease-in-out inline-block">Cerdas</span>
        </h2>

        <!-- Subheadline -->
        <p class="mt-6 text-white/85 font-medium max-w-2xl text-base sm:text-lg leading-relaxed">
            <strong class="text-[#e3cba8] font-semibold">SumberTani berbasis AI</strong> membantu petani mengelola musim tanam, mencatat panen, memantau stok, dan memasarkan produk olahan langsung ke pasar secara modern, transparan, dan terintegrasi.
        </p>

        <!-- CTAs: "Jelajahi Katalog Produk" & "Masuk Aplikasi" -->
        <div class="flex flex-col sm:flex-row items-center gap-4 mt-10 w-full sm:w-auto">
            <!-- CTA 1: Jelajahi Katalog Produk -->
            <a href="{{ route('catalog') }}" class="text-base font-bold text-[#391F18] bg-[#e3cba8] hover:bg-white transition-all px-8 py-3.5 rounded-xl border-2 border-[#391F18] shadow-[5px_5px_0px_0px_#391F18] hover:shadow-[7px_7px_0px_0px_#391F18] hover:-translate-y-1 flex items-center justify-center gap-2.5 w-full sm:w-auto">
                <span>Jelajahi Katalog Produk</span>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
                </svg>
            </a>

            <!-- CTA 2: Masuk Aplikasi -->
            <button onclick="handleAppRouting(event)" class="download-trigger text-base font-bold text-white bg-primary hover:bg-primary-dark transition-all px-8 py-3.5 rounded-xl border-2 border-[#391F18] shadow-[5px_5px_0px_0px_#391F18] hover:shadow-[7px_7px_0px_0px_#391F18] hover:-translate-y-1 flex items-center justify-center gap-2.5 w-full sm:w-auto animate-heartbeat">
                <span>Masuk Aplikasi</span>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6a2.25 2.25 0 0 0-2.25 2.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15m3 0 3-3m0 0-3-3m3 3H9" />
                </svg>
            </button>
        </div>

        <!-- Features Checklist -->
        <div class="flex flex-wrap items-center justify-center gap-6 mt-8 text-sm font-medium text-[#e3cba8]">
            <div class="flex items-center gap-2"><span class="text-green-400">✓</span> Terintegrasi AI & Mobile App</div>
            <div class="flex items-center gap-2"><span class="text-yellow-400">✓</span> Hilirisasi Produk Olahan Tani</div>
            <div class="flex items-center gap-2"><span class="text-blue-400">✓</span> Penjualan Terpusat & Transparan</div>
        </div>

        <!-- Mockup Dashboard -->
        <div class="mt-16 w-full max-w-4xl bg-white rounded-2xl shadow-[12px_12px_0px_0px_#391F18] border-2 border-[#391F18] p-4 md:p-8 animate-float relative z-10 text-left">
            <!-- Window controls -->
            <div class="flex items-center justify-between mb-6 pb-4 border-b border-gray-100">
                <div class="flex items-center gap-2">
                    <div class="w-3 h-3 rounded-full bg-red-500"></div>
                    <div class="w-3 h-3 rounded-full bg-yellow-500"></div>
                    <div class="w-3 h-3 rounded-full bg-green-500"></div>
                    <span class="text-xs text-gray-500 font-mono ml-2">SumberTani Dashboard v2.0</span>
                </div>
                <span class="text-xs bg-green-100 text-green-800 font-bold px-2.5 py-1 rounded-md">Live Real-time</span>
            </div>
            
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                <div class="bg-yellow-50 p-4 rounded-xl border border-yellow-200">
                    <p class="text-yellow-800 text-xs font-bold mb-1">Stok Panen Mentah</p>
                    <p class="text-yellow-700 text-xl font-black">4.500 kg</p>
                </div>
                <div class="bg-green-50 p-4 rounded-xl border border-green-200">
                    <p class="text-green-800 text-xs font-bold mb-1">Total Panen Musim</p>
                    <p class="text-green-700 text-xl font-black">12.400 kg</p>
                </div>
                <div class="bg-emerald-50 p-4 rounded-xl border border-emerald-200">
                    <p class="text-emerald-800 text-xs font-bold mb-1">Produk Olahan</p>
                    <p class="text-emerald-700 text-xl font-black">280 Unit</p>
                </div>
                <div class="bg-teal-50 p-4 rounded-xl border border-teal-200">
                    <p class="text-teal-800 text-xs font-bold mb-1">Laba Bersih Petani</p>
                    <p class="text-teal-700 text-xl font-black">Rp 28,6 jt</p>
                </div>
            </div>

            <!-- Chart mockup -->
            <div class="h-40 border border-gray-100 rounded-xl bg-gray-50 p-4 flex items-end gap-4 justify-between">
                <div class="w-full bg-green-300 rounded-t-md hover:bg-green-400 transition" style="height: 60%"></div>
                <div class="w-full bg-emerald-400 rounded-t-md hover:bg-emerald-500 transition" style="height: 80%"></div>
                <div class="w-full bg-green-300 rounded-t-md hover:bg-green-400 transition" style="height: 45%"></div>
                <div class="w-full bg-emerald-400 rounded-t-md hover:bg-emerald-500 transition" style="height: 90%"></div>
                <div class="w-full bg-green-300 rounded-t-md hover:bg-green-400 transition" style="height: 70%"></div>
                <div class="w-full bg-emerald-400 rounded-t-md hover:bg-emerald-500 transition" style="height: 100%"></div>
            </div>
        </div>
    </section>

    <!-- 3. FITUR SECTION -->
    <section id="fitur" class="w-full bg-transparent py-20 px-4">
        <div class="max-w-6xl mx-auto">
            <div class="text-center mb-16">
                <div class="inline-flex items-center gap-1.5 px-4 py-1.5 bg-[#e3cba8] border-2 border-[#391F18] shadow-[2px_2px_0px_0px_#391F18] rounded-full text-xs font-bold text-[#391F18] uppercase tracking-wide mb-4">
                    Fitur Unggulan Platform
                </div>
                <h2 class="text-4xl md:text-5xl font-heading font-black text-[#e3cba8]">Solusi Digital Komprehensif</h2>
                <p class="mt-3 text-white/80 max-w-xl mx-auto text-base">
                    Enam pilar utama yang menopang efisiensi operasional petani dan kesuksesan pemasaran hasil tani.
                </p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <!-- 1. Manajemen Musim Tanam -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-1.5 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 21v-8.25M15.75 21v-8.25M8.25 21v-8.25M3 9l9-6 9 6m-1.5 12V10.332A48.36 48.36 0 0 0 12 9.75c-2.551 0-5.056.2-7.5.582V21M3 21h18M12 6.75h.008v.008H12V6.75Z" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Manajemen Musim Tanam</h3>
                    <p class="text-gray-600 text-sm leading-relaxed">Rencanakan dan pantau seluruh siklus tanam, varietas bibit, dan perkiraan tanggal panen secara terjadwal dan terdata rapi.</p>
                </div>

                <!-- 2. Pencatatan Panen -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-1.5 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M6.827 6.175A2.31 2.31 0 0 1 5.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 0 0-1.134-.175 2.31 2.31 0 0 1-1.64-1.055l-.822-1.316a2.192 2.192 0 0 0-1.736-1.039 48.774 48.774 0 0 0-5.232 0 2.192 2.192 0 0 0-1.736 1.039l-.821 1.316Z" />
                            <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 12.75a4.5 4.5 0 1 1-9 0 4.5 4.5 0 0 1 9 0ZM18.75 10.5h.008v.008h-.008V10.5Z" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Pencatatan Panen</h3>
                    <p class="text-gray-600 text-sm leading-relaxed">Rekam hasil panen secara presisi lengkap dengan bukti foto dokumentasi, berat timbangan (kg), serta catatan blok kebun.</p>
                </div>

                <!-- 3. Manajemen Stok -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-1.5 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                            <path stroke-linecap="round" stroke-linejoin="round" d="m21 7.5-9-5.25L3 7.5m18 0-9 5.25m9-5.25v9l-9 5.25M3 7.5l9 5.25M3 7.5v9l9 5.25m0-9v9" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Manajemen Stok</h3>
                    <p class="text-gray-600 text-sm leading-relaxed">Pantau ketersediaan gudang komoditas mentah dan stok olahan secara real-time dengan audit mutasi keluar/masuk yang akurat.</p>
                </div>

                <!-- 4. Produk Olahan -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-1.5 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 21v-7.5a.75.75 0 0 1 .75-.75h3a.75.75 0 0 1 .75.75V21m-4.5 0H2.36m11.14 0H18m0 0h5.25M3.75 3h16.5A1.5 1.5 0 0 1 21.75 4.5v12.75a1.5 1.5 0 0 1-1.5 1.5H3.75a1.5 1.5 0 0 1-1.5-1.5V4.5A1.5 1.5 0 0 1 3.75 3Z" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Produk Olahan</h3>
                    <p class="text-gray-600 text-sm leading-relaxed">Daftarkan produk hilirisasi bernilai tambah tinggi lengkap dengan foto, penetapan harga jual, dan kontrol stok milik petani.</p>
                </div>

                <!-- 5. Penjualan & Pemasaran -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-1.5 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 3h1.386c.51 0 .955.343 1.087.835l.383 1.437M7.5 14.25a3 3 0 0 0-3 3h15.75m-12.75-3h11.218c1.121-2.3 2.1-4.684 2.924-7.138a60.114 60.114 0 0 0-16.536-1.84M7.5 14.25 5.106 5.272M6 20.25a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Zm12.75 0a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Penjualan & Pemasaran</h3>
                    <p class="text-gray-600 text-sm leading-relaxed">Pemasaran terpusat oleh Super Admin melalui katalog publik daring dan konfirmasi transaksi cepat melalui WhatsApp.</p>
                </div>

                <!-- 6. Laporan & Analitik -->
                <div class="bg-white p-6 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] hover:shadow-[8px_8px_0px_0px_#391F18] hover:-translate-y-1.5 transition-all">
                    <div class="w-12 h-12 bg-[#e3cba8]/20 text-[#3b2319] flex items-center justify-center rounded-xl mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Laporan & Analitik</h3>
                    <p class="text-gray-600 text-sm leading-relaxed">Kalkulasi otomatis pendapatan, rincian biaya produksi, dan laporan untung-rugi transparan per siklus tanam.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- 4. HILIRISASI & ETALASE PRODUK OLAHAN SECTION -->
    <section id="hilirisasi" class="w-full bg-transparent py-20 px-4 text-white relative">
        <div class="max-w-6xl mx-auto">
            <!-- Section Header: Edukasi & Value Proposition Hilirisasi -->
            <div class="text-center mb-16">
                <div class="inline-block px-4 py-1.5 bg-[#e3cba8] border-2 border-[#391F18] shadow-[2px_2px_0px_0px_#391F18] rounded-full text-xs font-bold text-[#391F18] uppercase tracking-wide mb-4">
                    Edukasi & Hilirisasi Produk Olahan
                </div>
                <h2 class="text-4xl md:text-5xl font-heading font-black text-[#e3cba8]">Dari Kebun Menuju Nilai Tambah Tinggi</h2>
                <p class="mt-3 text-white/80 max-w-3xl mx-auto text-base leading-relaxed">
                    SumberTani memberdayakan kelompok tani mitra untuk mengolah hasil panen mentah menjadi aneka komoditas pangan olahan bernilai jual tinggi, menjaga stabilitas harga saat panen raya, dan memperluas jangkauan pasar secara langsung.
                </p>
            </div>

            <!-- 3 Pilar Manfaat Hilirisasi -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16 text-left">
                <div class="bg-white/95 text-gray-900 rounded-2xl border-2 border-[#391F18] shadow-[5px_5px_0px_0px_#391F18] p-6 hover:-translate-y-1 transition-all">
                    <div class="w-12 h-12 rounded-xl bg-amber-100 text-amber-800 flex items-center justify-center font-bold text-xl mb-4">
                        📈
                    </div>
                    <h3 class="text-lg font-bold text-gray-900 mb-2">Nilai Tambah Ekonomis</h3>
                    <p class="text-gray-600 text-xs leading-relaxed">
                        Mengolah komoditas mentah (seperti kentang) menjadi olahan keripik atau tepung pati meningkatkan margin perolehan petani hingga 2.5× sampai 4× lipat dibandingkan menjual mentah di pasar tradisional.
                    </p>
                </div>

                <div class="bg-white/95 text-gray-900 rounded-2xl border-2 border-[#391F18] shadow-[5px_5px_0px_0px_#391F18] p-6 hover:-translate-y-1 transition-all">
                    <div class="w-12 h-12 rounded-xl bg-emerald-100 text-emerald-800 flex items-center justify-center font-bold text-xl mb-4">
                        🛡️
                    </div>
                    <h3 class="text-lg font-bold text-gray-900 mb-2">Penyangga Panen Raya</h3>
                    <p class="text-gray-600 text-xs leading-relaxed">
                        Saat musim panen raya menyebabkan pasokan melimpah dan harga pasar anjlok, unit pengolahan hasil panen menyerap stok berlebih untuk diolah menjadi produk berdaya simpan panjang.
                    </p>
                </div>

                <div class="bg-white/95 text-gray-900 rounded-2xl border-2 border-[#391F18] shadow-[5px_5px_0px_0px_#391F18] p-6 hover:-translate-y-1 transition-all">
                    <div class="w-12 h-12 rounded-xl bg-teal-100 text-teal-800 flex items-center justify-center font-bold text-xl mb-4">
                        🤝
                    </div>
                    <h3 class="text-lg font-bold text-gray-900 mb-2">Pemberdayaan Kelompok Tani</h3>
                    <p class="text-gray-600 text-xs leading-relaxed">
                        Mendorong kemitraan erat antara petani budidaya dan kelompok wanita tani (KWT), menciptakan lapangan kerja produktif baru bagi masyarakat pedesaan.
                    </p>
                </div>
            </div>

            <!-- Featured Products Teaser -->
            @if(isset($featuredProducts) && count($featuredProducts) > 0)
                <div class="mb-12">
                    <div class="flex items-center justify-between mb-6">
                        <div>
                            <span class="text-xs font-bold text-[#e3cba8] uppercase tracking-wider block">Etalase Pilihan</span>
                            <h3 class="text-2xl font-bold text-white">Produk Olahan Unggulan</h3>
                        </div>
                        <a href="{{ route('catalog') }}" class="text-xs sm:text-sm font-bold text-[#e3cba8] hover:text-white flex items-center gap-1.5 transition">
                            <span>Lihat Semua Produk</span>
                            <span class="text-base">➔</span>
                        </a>
                    </div>

                    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 text-left">
                        @foreach($featuredProducts as $item)
                            <div class="bg-white rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] overflow-hidden flex flex-col justify-between hover:-translate-y-1 transition-all group">
                                <div class="w-full h-40 bg-gray-100 overflow-hidden border-b-2 border-[#391F18] flex items-center justify-center">
                                    @if($item->photo_url)
                                        <img src="{{ $item->photo_url }}" alt="{{ $item->name }}" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300">
                                    @else
                                        <img src="{{ asset('images/logo.png') }}" alt="{{ $item->name }}" class="w-16 h-16 object-contain opacity-50">
                                    @endif
                                </div>
                                <div class="p-4 flex-1 flex flex-col justify-between">
                                    <div>
                                        <span class="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded block w-fit mb-1">
                                            Petani: {{ $item->owner?->farm_name ?? $item->owner?->name ?? 'Mitra Petani' }}
                                        </span>
                                        <h4 class="text-sm font-bold text-gray-900 group-hover:text-primary transition-colors leading-snug">
                                            {{ $item->name }}
                                        </h4>
                                    </div>
                                    <div class="pt-3 mt-3 border-t border-gray-100 flex items-center justify-between">
                                        <span class="text-sm font-extrabold text-primary">
                                            Rp {{ number_format($item->price, 0, ',', '.') }}
                                        </span>
                                        <a href="{{ route('catalog') }}" class="text-xs font-bold text-[#391F18] bg-[#e3cba8] hover:bg-white px-2.5 py-1 rounded-lg border border-[#391F18] transition">
                                            Detail ➔
                                        </a>
                                    </div>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            @endif

            <!-- High-Impact CTA Banner to Dedicated /katalog -->
            <div class="bg-gradient-to-r from-[#391F18]/90 via-[#2d6a4f]/80 to-[#391F18]/90 backdrop-blur-md rounded-3xl border-2 border-[#e3cba8]/50 p-8 sm:p-10 shadow-2xl text-center">
                <div class="max-w-2xl mx-auto space-y-4">
                    <span class="inline-block px-3 py-1 bg-emerald-500/20 text-emerald-300 rounded-full text-[11px] font-bold uppercase tracking-wider border border-emerald-400/30">
                        🛒 Etalase Publik Tersedia
                    </span>
                    <h3 class="text-2xl sm:text-3xl font-heading font-black text-[#e3cba8]">
                        Jelajahi Katalog Lengkap Produk Olahan Tani
                    </h3>
                    <p class="text-white/80 text-xs sm:text-sm leading-relaxed">
                        Lihat aneka ragam produk olahan karya petani binaan kami, cek ketersediaan stok aktual, dan pesan langsung melalui WhatsApp resmi Super Admin dengan proses mudah.
                    </p>
                    <div class="pt-2">
                        <a href="{{ route('catalog') }}" class="inline-flex items-center gap-2.5 text-sm sm:text-base font-bold text-[#391F18] bg-[#e3cba8] hover:bg-white transition-all px-8 py-3.5 rounded-2xl border-2 border-[#391F18] shadow-[5px_5px_0px_0px_#000] hover:shadow-[7px_7px_0px_0px_#000] hover:-translate-y-1">
                            <span>Buka Katalog Produk (/katalog)</span>
                            <svg xmlns="http://www.w3.org/2000/svg" class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                            </svg>
                        </a>
                    </div>
                </div>
            </div>

            <!-- Tracking Bar Pelacakan Pesanan Pelanggan -->
            <div class="mt-14 max-w-2xl mx-auto bg-[#391F18]/80 backdrop-blur-md border-2 border-[#e3cba8]/40 rounded-2xl p-6 shadow-xl text-center">
                <div class="inline-flex items-center gap-2 text-xs font-bold text-[#e3cba8] uppercase tracking-wider mb-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="size-4 text-[#e3cba8]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                    Lacak Pesanan Publik
                </div>
                <h3 class="text-lg font-bold text-white mb-2">Sudah Memesan? Cek Status Pesanan Anda</h3>
                <p class="text-white/70 text-xs mb-4">Masukkan kode pesanan Anda (contoh: <span class="font-mono text-[#e3cba8]">ORD-20260925-XXXX</span>) untuk melihat progres pemrosesan pesanan.</p>
                <form onsubmit="event.preventDefault(); trackOrderFromInput();" class="flex flex-col sm:flex-row gap-2 max-w-lg mx-auto">
                    <input type="text" id="landing-tracking-input" placeholder="Masukkan Kode Pesanan..." required class="flex-1 px-4 py-2.5 rounded-xl bg-white/10 border border-[#e3cba8]/40 text-white placeholder-white/40 focus:outline-none focus:border-[#e3cba8] text-sm font-mono uppercase">
                    <button type="submit" class="px-6 py-2.5 bg-[#e3cba8] hover:bg-white text-[#391F18] font-bold rounded-xl text-sm transition-all shadow-[2px_2px_0px_0px_#000]">
                        Lacak Status
                    </button>
                </form>
            </div>
        </div>
    </section>

    <!-- 5. CARA KERJA SECTION -->
    <section id="cara-kerja" class="w-full bg-transparent py-20 px-4 text-white relative">
        <div class="max-w-6xl mx-auto">
            <div class="text-center mb-16">
                <div class="inline-block px-4 py-1.5 bg-[#e3cba8] border-2 border-[#391F18] shadow-[2px_2px_0px_0px_#391F18] rounded-full text-xs font-bold text-[#391F18] uppercase tracking-wide mb-4">
                    Alur & Mekanisme Sistem
                </div>
                <h2 class="text-4xl md:text-5xl font-heading font-black text-[#e3cba8]">Cara Kerja Ekosistem SumberTani</h2>
                <p class="mt-3 text-white/80 max-w-2xl mx-auto text-base">
                    Alur hilirisasi terintegrasi: dari hasil keringat petani hingga pesanan terkonfirmasi dan stok terpotong secara transparan.
                </p>
            </div>

            <!-- Workflow Pipeline Grid (8 Langkah Terstruktur) -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 relative text-left">
                <!-- Step 1: Petani -->
                <div class="bg-white/95 text-gray-900 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] p-5 flex flex-col justify-between hover:-translate-y-1 transition-all">
                    <div>
                        <div class="flex items-center justify-between mb-3">
                            <span class="w-8 h-8 rounded-lg bg-emerald-100 text-emerald-800 font-extrabold text-sm flex items-center justify-center">01</span>
                            <span class="text-xs font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded">Hulu</span>
                        </div>
                        <h4 class="text-lg font-bold text-gray-900 mb-1.5">Petani</h4>
                        <p class="text-gray-600 text-xs leading-relaxed">
                            Mitra petani membudidayakan lahan dan mencatat hasil panen komoditas unggulan di aplikasi.
                        </p>
                    </div>
                    <div class="mt-4 pt-3 border-t border-gray-100 flex items-center text-xs text-gray-400 font-semibold gap-1">
                        <span>Lanjut ke Olahan</span> ➔
                    </div>
                </div>

                <!-- Step 2: Produk Olahan -->
                <div class="bg-white/95 text-gray-900 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] p-5 flex flex-col justify-between hover:-translate-y-1 transition-all">
                    <div>
                        <div class="flex items-center justify-between mb-3">
                            <span class="w-8 h-8 rounded-lg bg-emerald-100 text-emerald-800 font-extrabold text-sm flex items-center justify-center">02</span>
                            <span class="text-xs font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded">Hilirisasi</span>
                        </div>
                        <h4 class="text-lg font-bold text-gray-900 mb-1.5">Produk Olahan</h4>
                        <p class="text-gray-600 text-xs leading-relaxed">
                            Petani mengolah panen mentah menjadi produk bernilai tambah dan mendaftarkannya lengkap dengan foto & stok awal.
                        </p>
                    </div>
                    <div class="mt-4 pt-3 border-t border-gray-100 flex items-center text-xs text-gray-400 font-semibold gap-1">
                        <span>Publikasi Etalase</span> ➔
                    </div>
                </div>

                <!-- Step 3: Katalog Publik -->
                <div class="bg-white/95 text-gray-900 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] p-5 flex flex-col justify-between hover:-translate-y-1 transition-all">
                    <div>
                        <div class="flex items-center justify-between mb-3">
                            <span class="w-8 h-8 rounded-lg bg-emerald-100 text-emerald-800 font-extrabold text-sm flex items-center justify-center">03</span>
                            <span class="text-xs font-bold text-blue-700 bg-blue-50 px-2 py-0.5 rounded">Showcase</span>
                        </div>
                        <h4 class="text-lg font-bold text-gray-900 mb-1.5">Katalog Publik</h4>
                        <p class="text-gray-600 text-xs leading-relaxed">
                            Produk olahan petani otomatis tampil di etalase web secara publik untuk menjangkau pangsa pasar luas.
                        </p>
                    </div>
                    <div class="mt-4 pt-3 border-t border-gray-100 flex items-center text-xs text-gray-400 font-semibold gap-1">
                        <span>Dilihat Pasar</span> ➔
                    </div>
                </div>

                <!-- Step 4: Customer -->
                <div class="bg-white/95 text-gray-900 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] p-5 flex flex-col justify-between hover:-translate-y-1 transition-all">
                    <div>
                        <div class="flex items-center justify-between mb-3">
                            <span class="w-8 h-8 rounded-lg bg-emerald-100 text-emerald-800 font-extrabold text-sm flex items-center justify-center">04</span>
                            <span class="text-xs font-bold text-purple-700 bg-purple-50 px-2 py-0.5 rounded">Pasar</span>
                        </div>
                        <h4 class="text-lg font-bold text-gray-900 mb-1.5">Customer</h4>
                        <p class="text-gray-600 text-xs leading-relaxed">
                            Calon pembeli menelusuri katalog, mengecek harga serta stok aktual, lalu memilih produk olahan yang diminati.
                        </p>
                    </div>
                    <div class="mt-4 pt-3 border-t border-gray-100 flex items-center text-xs text-gray-400 font-semibold gap-1">
                        <span>Kirim Order</span> ➔
                    </div>
                </div>

                <!-- Step 5: WhatsApp -->
                <div class="bg-white/95 text-gray-900 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] p-5 flex flex-col justify-between hover:-translate-y-1 transition-all">
                    <div>
                        <div class="flex items-center justify-between mb-3">
                            <span class="w-8 h-8 rounded-lg bg-green-100 text-green-800 font-extrabold text-sm flex items-center justify-center">05</span>
                            <span class="text-xs font-bold text-green-700 bg-green-50 px-2 py-0.5 rounded">Chat Order</span>
                        </div>
                        <h4 class="text-lg font-bold text-gray-900 mb-1.5">WhatsApp</h4>
                        <p class="text-gray-600 text-xs leading-relaxed">
                            Customer mengirim *order request* via WhatsApp resmi dengan format pesan nama produk dan estimasi harga otomatis.
                        </p>
                    </div>
                    <div class="mt-4 pt-3 border-t border-gray-100 flex items-center text-xs text-gray-400 font-semibold gap-1">
                        <span>Diterima Admin</span> ➔
                    </div>
                </div>

                <!-- Step 6: Super Admin -->
                <div class="bg-white/95 text-gray-900 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] p-5 flex flex-col justify-between hover:-translate-y-1 transition-all">
                    <div>
                        <div class="flex items-center justify-between mb-3">
                            <span class="w-8 h-8 rounded-lg bg-amber-100 text-amber-800 font-extrabold text-sm flex items-center justify-center">06</span>
                            <span class="text-xs font-bold text-amber-700 bg-amber-50 px-2 py-0.5 rounded">Verifikasi</span>
                        </div>
                        <h4 class="text-lg font-bold text-gray-900 mb-1.5">Super Admin</h4>
                        <p class="text-gray-600 text-xs leading-relaxed">
                            Super Admin memvalidasi ketersediaan stok produk petani, menentukan biaya ongkir, dan mengonfirmasi bukti bayar.
                        </p>
                    </div>
                    <div class="mt-4 pt-3 border-t border-gray-100 flex items-center text-xs text-gray-400 font-semibold gap-1">
                        <span>Pencatatan Riil</span> ➔
                    </div>
                </div>

                <!-- Step 7: Penjualan -->
                <div class="bg-white/95 text-gray-900 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] p-5 flex flex-col justify-between hover:-translate-y-1 transition-all">
                    <div>
                        <div class="flex items-center justify-between mb-3">
                            <span class="w-8 h-8 rounded-lg bg-blue-100 text-blue-800 font-extrabold text-sm flex items-center justify-center">07</span>
                            <span class="text-xs font-bold text-blue-700 bg-blue-50 px-2 py-0.5 rounded">Transaksi</span>
                        </div>
                        <h4 class="text-lg font-bold text-gray-900 mb-1.5">Penjualan</h4>
                        <p class="text-gray-600 text-xs leading-relaxed">
                            Super Admin mencatat transaksi penjualan resmi di aplikasi atas nama petani pemilik agar laba tercatat akurat.
                        </p>
                    </div>
                    <div class="mt-4 pt-3 border-t border-gray-100 flex items-center text-xs text-gray-400 font-semibold gap-1">
                        <span>Sinkronisasi</span> ➔
                    </div>
                </div>

                <!-- Step 8: Stock Update -->
                <div class="bg-white/95 text-gray-900 rounded-2xl border-2 border-[#391F18] shadow-[4px_4px_0px_0px_#391F18] p-5 flex flex-col justify-between hover:-translate-y-1 transition-all">
                    <div>
                        <div class="flex items-center justify-between mb-3">
                            <span class="w-8 h-8 rounded-lg bg-teal-100 text-teal-800 font-extrabold text-sm flex items-center justify-center">08</span>
                            <span class="text-xs font-bold text-teal-700 bg-teal-50 px-2 py-0.5 rounded">Otomatis</span>
                        </div>
                        <h4 class="text-lg font-bold text-gray-900 mb-1.5">Stock Update</h4>
                        <p class="text-gray-600 text-xs leading-relaxed">
                            Saldo stok produk olahan otomatis berkurang dan tercatat dalam riwayat mutasi. Status beralih otomatis saat habis.
                        </p>
                    </div>
                    <div class="mt-4 pt-3 border-t border-gray-100 flex items-center text-xs text-teal-600 font-bold gap-1">
                        <span>Selesai & Sinkron ✓</span>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- 6. TENTANG / MANFAAT SECTION -->
    <section id="tentang" class="w-full bg-transparent py-20 px-4">
        <div class="max-w-6xl mx-auto">
            <div class="text-center mb-16">
                <div class="inline-flex items-center gap-1.5 px-4 py-1.5 bg-yellow-100 border border-yellow-200 rounded-full text-xs font-bold text-yellow-800 uppercase tracking-wide mb-4">
                    Tentang & Manfaat Platform
                </div>
                <h2 class="text-4xl md:text-5xl font-heading font-black text-[#e3cba8]">Manfaat Nyata Bagi Seluruh Pihak</h2>
                <p class="mt-3 text-white/80 max-w-2xl mx-auto text-base">
                    SumberTani berbasis AI hadir menciptakan ekosistem pertanian yang saling menguntungkan antara petani, pengelola, dan konsumen.
                </p>
            </div>

            <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 text-left">
                <!-- 1. Untuk Petani -->
                <div class="bg-white rounded-3xl border-2 border-[#391F18] shadow-[6px_6px_0px_0px_#391F18] p-8 flex flex-col justify-between hover:-translate-y-1 transition-all">
                    <div>
                        <div class="w-14 h-14 bg-emerald-100 text-emerald-800 rounded-2xl flex items-center justify-center mb-6 shadow-inner">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="size-7">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z" />
                            </svg>
                        </div>
                        <h3 class="text-2xl font-black text-gray-900 mb-3">Untuk Petani</h3>
                        <p class="text-gray-600 text-sm mb-6 leading-relaxed">
                            Fokus pada budidaya dan peningkatan mutu hasil panen tanpa beban repot memasarkan sendiri ke konsumen eceran.
                        </p>
                        
                        <ul class="space-y-3 text-sm text-gray-700">
                            <li class="flex items-start gap-2.5">
                                <span class="text-emerald-600 font-bold">✓</span>
                                <span><strong>Kepemilikan Stok Penuh:</strong> Produk olahan tetap 100% milik petani (<code class="text-xs bg-gray-100 px-1 py-0.5 rounded text-gray-700">owner_id</code>).</span>
                            </li>
                            <li class="flex items-start gap-2.5">
                                <span class="text-emerald-600 font-bold">✓</span>
                                <span><strong>Pencatatan Keuangan Rapi:</strong> Pantau biaya modal, hasil panen, dan laba-rugi per musim secara transparan.</span>
                            </li>
                            <li class="flex items-start gap-2.5">
                                <span class="text-emerald-600 font-bold">✓</span>
                                <span><strong>Nilai Tambah Hasil Tani:</strong> Hilirisasi komoditas mentah menjadi olahan dengan keuntungan lebih tinggi.</span>
                            </li>
                        </ul>
                    </div>
                    <div class="mt-8 pt-4 border-t border-gray-100 text-xs font-semibold text-emerald-700">
                        Pemberdayaan Petani Mandiri
                    </div>
                </div>

                <!-- 2. Untuk Super Admin -->
                <div class="bg-white rounded-3xl border-2 border-[#391F18] shadow-[6px_6px_0px_0px_#391F18] p-8 flex flex-col justify-between hover:-translate-y-1 transition-all">
                    <div>
                        <div class="w-14 h-14 bg-amber-100 text-amber-800 rounded-2xl flex items-center justify-center mb-6 shadow-inner">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="size-7">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 6a7.5 7.5 0 1 0 7.5 7.5h-7.5V6Z" />
                                <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 10.5H21A7.5 7.5 0 0 0 13.5 3v7.5Z" />
                            </svg>
                        </div>
                        <h3 class="text-2xl font-black text-gray-900 mb-3">Untuk Super Admin</h3>
                        <p class="text-gray-600 text-sm mb-6 leading-relaxed">
                            Pusat kendali operasional pemasaran, verifikasi transaksi, dan pengawasan inventori seluruh mitra tani.
                        </p>
                        
                        <ul class="space-y-3 text-sm text-gray-700">
                            <li class="flex items-start gap-2.5">
                                <span class="text-amber-600 font-bold">✓</span>
                                <span><strong>Sentralisasi Penjualan:</strong> Proses transaksi terverifikasi dan hindari duplikasi inventori.</span>
                            </li>
                            <li class="flex items-start gap-2.5">
                                <span class="text-amber-600 font-bold">✓</span>
                                <span><strong>Asisten AI Operasional:</strong> Didukung Chatbot AI khusus untuk ringkasan pemasaran dan analisis stok.</span>
                            </li>
                            <li class="flex items-start gap-2.5">
                                <span class="text-amber-600 font-bold">✓</span>
                                <span><strong>Laporan Agregat Akurat:</strong> Pantau performa laba rugi gabungan seluruh kelompok tani binaan.</span>
                            </li>
                        </ul>
                    </div>
                    <div class="mt-8 pt-4 border-t border-gray-100 text-xs font-semibold text-amber-700">
                        Manajemen Profesional & Terintegrasi
                    </div>
                </div>

                <!-- 3. Untuk Customer -->
                <div class="bg-white rounded-3xl border-2 border-[#391F18] shadow-[6px_6px_0px_0px_#391F18] p-8 flex flex-col justify-between hover:-translate-y-1 transition-all">
                    <div>
                        <div class="w-14 h-14 bg-teal-100 text-teal-800 rounded-2xl flex items-center justify-center mb-6 shadow-inner">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="size-7">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 10.5V6a3.75 3.75 0 1 0-7.5 0v4.5m11.356-1.993 1.263 12c.07.665-.45 1.243-1.119 1.243H4.25a1.125 1.125 0 0 1-1.12-1.243l1.264-12A1.125 1.125 0 0 1 5.513 7.5h12.974c.576 0 1.059.435 1.119 1.007ZM8.625 10.5a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm7.5 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" />
                            </svg>
                        </div>
                        <h3 class="text-2xl font-black text-gray-900 mb-3">Untuk Customer</h3>
                        <p class="text-gray-600 text-sm mb-6 leading-relaxed">
                            Mendapatkan produk olahan bermutu langsung dari sumber aslinya dengan proses pemesanan yang praktis.
                        </p>
                        
                        <ul class="space-y-3 text-sm text-gray-700">
                            <li class="flex items-start gap-2.5">
                                <span class="text-teal-600 font-bold">✓</span>
                                <span><strong>Kualitas Asli & Higienis:</strong> Produk olahan segar hasil hilirisasi tangan petani binaan terpercaya.</span>
                            </li>
                            <li class="flex items-start gap-2.5">
                                <span class="text-teal-600 font-bold">✓</span>
                                <span><strong>Pesan Cepat via WhatsApp:</strong> Pesan instan tanpa perlu repot mengunduh aplikasi atau membuat akun baru.</span>
                            </li>
                            <li class="flex items-start gap-2.5">
                                <span class="text-teal-600 font-bold">✓</span>
                                <span><strong>Kepastian Stok Aktual:</strong> Informasi ketersediaan unit terupdate secara langsung dari sistem.</span>
                            </li>
                        </ul>
                    </div>
                    <div class="mt-8 pt-4 border-t border-gray-100 text-xs font-semibold text-teal-700">
                        Belanja Praktis & Berdayakan Petani
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- 7. CTA SECTION -->
    <section class="w-full bg-transparent py-20 px-4">
        <div class="max-w-4xl mx-auto bg-[#895A42] rounded-3xl border-2 border-[#391F18] p-10 md:p-16 text-center text-white shadow-[12px_12px_0px_0px_#391F18] relative overflow-hidden">
            <!-- Decorative circle -->
            <div class="absolute top-[-50px] right-[-50px] w-64 h-64 bg-white/10 rounded-full blur-2xl"></div>
            <div class="absolute bottom-[-50px] left-[-50px] w-64 h-64 bg-[#e3cba8]/20 rounded-full blur-2xl"></div>
            
            <span class="inline-block px-4 py-1.5 bg-[#e3cba8] text-[#391F18] rounded-full text-xs font-bold uppercase tracking-wide mb-4 shadow-sm relative z-10">
                Mulai Sekarang
            </span>
            <h2 class="text-4xl md:text-5xl font-heading font-black mb-6 relative z-10">Temukan Produk Olahan Hasil Tani</h2>
            <p class="text-white/90 mb-10 max-w-2xl mx-auto relative z-10 font-medium text-base sm:text-lg">
                Jelajahi ragam produk olahan binaan petani lokal kami atau masuk ke aplikasi untuk mulai mendigitalkan pencatatan dan hilirisasi usaha pertanian Anda.
            </p>
            
            <div class="flex flex-col sm:flex-row items-center justify-center gap-4 relative z-10">
                <a href="{{ route('catalog') }}" class="text-base font-bold text-[#391F18] bg-[#e3cba8] hover:bg-white transition-all px-8 py-3.5 rounded-xl border-2 border-[#391F18] shadow-[5px_5px_0px_0px_#391F18] hover:shadow-[7px_7px_0px_0px_#391F18] hover:-translate-y-1 flex items-center justify-center gap-2 w-full sm:w-auto">
                    <span>Lihat Katalog Produk</span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
                    </svg>
                </a>
                <button onclick="handleAppRouting(event)" class="download-trigger text-base font-bold text-white bg-primary hover:bg-primary-dark transition px-8 py-3.5 rounded-xl border-2 border-[#391F18] shadow-[5px_5px_0px_0px_#391F18] hover:shadow-[7px_7px_0px_0px_#391F18] hover:-translate-y-1 flex items-center justify-center gap-2 w-full sm:w-auto animate-heartbeat">
                    <span>Masuk Aplikasi</span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6a2.25 2.25 0 0 0-2.25 2.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15m3 0 3-3m0 0-3-3m3 3H9" />
                    </svg>
                </button>
            </div>
            
            <div class="flex flex-wrap items-center justify-center gap-6 mt-8 text-sm font-medium text-[#e3cba8] relative z-10">
                <div class="flex items-center gap-2"><span>✓</span> Terhubung WhatsApp</div>
                <div class="flex items-center gap-2"><span>✓</span> Bebas Biaya Pendaftaran</div>
                <div class="flex items-center gap-2"><span>✓</span> Binaan Petani Terpercaya</div>
            </div>
        </div>
    </section>

    <!-- 8. FOOTER -->
    <footer class="backdrop-blur-md bg-[#A39987]/90 border-t border-[#5D3A2F]/50 py-12 px-4 text-white">
        <div class="max-w-6xl mx-auto flex flex-col md:flex-row justify-between items-center gap-6">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl overflow-hidden bg-white ring-1 ring-white/10 p-1 flex items-center justify-center">
                    <img src="{{ asset('images/logo.png') }}" alt="SumberTani" class="w-full h-full object-contain">
                </div>
                <div>
                    <span class="font-bold text-white text-base tracking-tight block">SumberTani berbasis AI</span>
                    <span class="text-[11px] text-white/70 block">Platform Manajemen & Hilirisasi Pertanian</span>
                </div>
            </div>
            
            <div class="flex flex-wrap items-center justify-center gap-6 text-sm text-white/90 font-medium">
                <a href="#beranda" class="hover:text-white transition">Beranda</a>
                <a href="#fitur" class="hover:text-white transition">Fitur</a>
                <a href="#hilirisasi" class="hover:text-white transition">Hilirisasi</a>
                <a href="{{ route('catalog') }}" class="hover:text-[#e3cba8] transition font-bold">Katalog Produk</a>
                <a href="#cara-kerja" class="hover:text-white transition">Cara Kerja</a>
                <a href="#tentang" class="hover:text-white transition">Tentang SumberTani</a>
            </div>
            
            <div class="text-xs text-white/70 text-center md:text-right">
                © 2026 SumberTani berbasis AI. All rights reserved.
            </div>
        </div>
    </footer>

    <!-- Scripts: App Routing, Particle Explosions, Smooth Scrolling, & Animations -->
    <script>
        // Mobile Menu Toggle
        const mobileMenuButton = document.getElementById('mobile-menu-button');
        const mobileMenu = document.getElementById('mobile-menu');
        const hamburgerIcon = document.getElementById('hamburger-icon');
        const closeIcon = document.getElementById('close-icon');

        if (mobileMenuButton && mobileMenu) {
            mobileMenuButton.addEventListener('click', () => {
                mobileMenu.classList.toggle('hidden');
                hamburgerIcon.classList.toggle('hidden');
                closeIcon.classList.toggle('hidden');
            });

            // Auto close mobile menu on click link
            document.querySelectorAll('.mobile-nav-link').forEach(link => {
                link.addEventListener('click', () => {
                    mobileMenu.classList.add('hidden');
                    hamburgerIcon.classList.remove('hidden');
                    closeIcon.classList.add('hidden');
                });
            });
        }

        // Deep Linking / App Routing
        function handleAppRouting(event) {
            triggerPotatoExplosion(event);

            var appScheme = "sumbertani://open";
            var downloadUrl = "/download/sumbertani.apk";

            window.location.href = appScheme;

            setTimeout(function() {
                window.location.href = downloadUrl;
            }, 5200);
        }

        function triggerPotatoExplosion(event) {
            const container = document.getElementById('potato-explosion-container');
            if (!container) return;

            const explosionEmoji = '🥔';

            const targetButton = event?.currentTarget || event?.target.closest('button');
            const buttonRect = targetButton?.getBoundingClientRect();
            const originX = buttonRect ? buttonRect.left + buttonRect.width / 2 : window.innerWidth / 2;
            const originY = buttonRect ? buttonRect.top + buttonRect.height / 2 : window.innerHeight / 2;

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
                particle.style.opacity = '0';
                particle.style.fontSize = `${size}px`;
                particle.style.display = 'flex';
                particle.style.alignItems = 'center';
                particle.style.justifyContent = 'center';
                particle.style.transform = 'translate(-50%, -50%) scale(0.8) rotate(0deg)';
                particle.style.transition = 'transform 0.6s ease-out, opacity 0.2s ease, left 2s ease-in, top 2s ease-in';
                particle.textContent = explosionEmoji;
                container.appendChild(particle);

                const angle = Math.random() * Math.PI * 2;
                const distance = 180 + Math.random() * 80;
                const burstX = Math.cos(angle) * distance;
                const burstY = Math.sin(angle) * distance * -1;
                const rotate = Math.random() * 720;

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

        // Scroll Animations (IntersectionObserver)
        document.addEventListener('DOMContentLoaded', function() {
            const observerOptions = {
                root: null,
                rootMargin: '0px',
                threshold: 0.12
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

            const animatedElements = document.querySelectorAll('section > div, .grid > div');
            animatedElements.forEach(el => {
                el.classList.add('transition-all', 'duration-700', 'opacity-0', 'translate-y-8');
                observer.observe(el);
            });

            // Animated Headline Word
            const words = ["Cerdas", "Terintegrasi", "Modern", "Efisien"];
            let wordIndex = 0;
            const animatedWordElement = document.getElementById("animated-word");
            
            if (animatedWordElement) {
                setInterval(() => {
                    animatedWordElement.style.opacity = '0';
                    animatedWordElement.style.transform = 'translateY(10px)';
                    
                    setTimeout(() => {
                        wordIndex = (wordIndex + 1) % words.length;
                        animatedWordElement.textContent = words[wordIndex];
                        animatedWordElement.style.opacity = '1';
                        animatedWordElement.style.transform = 'translateY(0)';
                    }, 400);
                }, 2200);
            }

            // Cursor Blob Follower
            const cursorBlob = document.getElementById('cursor-blob');
            if (cursorBlob) {
                document.addEventListener('mousemove', (e) => {
                    cursorBlob.style.transform = `translate(${e.clientX}px, ${e.clientY}px)`;
                });
            }
        });

        // ─── Order & WhatsApp Handling ─────────────────────────────────────
        var currentMaxStock = 0;
        var superAdminPhone = '{{ $cleanPhone ?? "6281234567890" }}';

        function openOrderModal(id, name, price, stock, farmer) {
            currentMaxStock = stock;
            document.getElementById('order-product-id').value = id;
            document.getElementById('order-product-name').value = name;
            document.getElementById('order-product-price').value = price;
            document.getElementById('order-product-farmer').value = farmer;

            document.getElementById('order-summary-name').textContent = name;
            document.getElementById('order-summary-farmer').textContent = farmer;
            document.getElementById('order-summary-price').textContent = 'Rp ' + Number(price).toLocaleString('id-ID');
            document.getElementById('order-summary-stock').textContent = 'Tersedia: ' + stock + ' unit';
            document.getElementById('order-max-stock-hint').textContent = 'Maksimal: ' + stock + ' unit';

            var qtyInput = document.getElementById('order-quantity');
            qtyInput.max = stock;
            qtyInput.value = 1;

            document.getElementById('order-error-message').classList.add('hidden');
            calculateOrderTotal();

            document.getElementById('modal-order-checkout').classList.remove('hidden');
        }

        function closeOrderModal() {
            document.getElementById('modal-order-checkout').classList.add('hidden');
        }

        function adjustOrderQty(delta) {
            var qtyInput = document.getElementById('order-quantity');
            var val = parseInt(qtyInput.value) || 1;
            val += delta;
            if (val < 1) val = 1;
            if (val > currentMaxStock) val = currentMaxStock;
            qtyInput.value = val;
            calculateOrderTotal();
        }

        function calculateOrderTotal() {
            var price = parseFloat(document.getElementById('order-product-price').value) || 0;
            var qty = parseInt(document.getElementById('order-quantity').value) || 1;
            if (qty > currentMaxStock) {
                qty = currentMaxStock;
                document.getElementById('order-quantity').value = qty;
            }
            var total = price * qty;
            document.getElementById('order-total-display').textContent = 'Rp ' + total.toLocaleString('id-ID');
        }

        async function submitOrderCheckout() {
            var btn = document.getElementById('btn-submit-order');
            var errEl = document.getElementById('order-error-message');
            errEl.classList.add('hidden');

            var productId = parseInt(document.getElementById('order-product-id').value);
            var productName = document.getElementById('order-product-name').value;
            var farmerName = document.getElementById('order-product-farmer').value;
            var price = parseFloat(document.getElementById('order-product-price').value);
            var qty = parseInt(document.getElementById('order-quantity').value) || 1;
            var customerName = document.getElementById('order-customer-name').value.trim();
            var customerPhone = document.getElementById('order-customer-phone').value.trim();
            var customerAddress = document.getElementById('order-customer-address').value.trim();
            var notes = document.getElementById('order-notes').value.trim();

            if (!customerName || !customerPhone) {
                errEl.textContent = 'Nama dan Nomor WhatsApp wajib diisi.';
                errEl.classList.remove('hidden');
                return;
            }

            btn.disabled = true;
            btn.innerHTML = '<span>Memproses Pesanan...</span>';

            try {
                var response = await fetch('/api/catalog/orders', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        customer_name: customerName,
                        customer_phone: customerPhone,
                        customer_address: customerAddress || null,
                        notes: notes || null,
                        processed_product_id: productId,
                        quantity: qty
                    })
                });

                var resData = await response.json();

                if (!response.ok || !resData.success) {
                    throw new Error(resData.message || 'Gagal membuat pesanan');
                }

                var orderCode = resData.data.order_code;
                var total = price * qty;

                // Format WhatsApp Message
                var waMsg = "Halo Admin SumberTani berbasis AI,\n\n" +
                            "Saya ingin memesan produk olahan:\n" +
                            "Kode Pesanan: " + orderCode + "\n" +
                            "Produk: " + productName + "\n" +
                            "Petani: " + farmerName + "\n" +
                            "Jumlah: " + qty + " unit\n" +
                            "Harga: Rp" + price.toLocaleString('id-ID') + "\n" +
                            "Estimasi Total: Rp" + total.toLocaleString('id-ID') + "\n\n" +
                            "Nama Pemesan: " + customerName + "\n" +
                            "No. HP: " + customerPhone + "\n" +
                            (customerAddress ? "Alamat: " + customerAddress + "\n" : "") +
                            (notes ? "Catatan: " + notes + "\n" : "");

                var waUrl = "https://wa.me/" + superAdminPhone + "?text=" + encodeURIComponent(waMsg);

                closeOrderModal();

                // Open WhatsApp in new tab
                window.open(waUrl, '_blank');

                // Open Confirmation & Public Tracking Modal
                openTrackingModal(orderCode);
            } catch (err) {
                errEl.textContent = err.message || 'Terjadi kesalahan saat memproses pesanan.';
                errEl.classList.remove('hidden');
            } finally {
                btn.disabled = false;
                btn.innerHTML = '<span>Pesan & Lanjut WhatsApp</span>';
            }
        }

        // ─── Public Tracking Modal Logic ──────────────────────────────────
        function closeTrackingModal() {
            document.getElementById('modal-order-tracking').classList.add('hidden');
        }

        function trackOrderFromInput() {
            var code = document.getElementById('landing-tracking-input').value.trim();
            if (!code) return;
            openTrackingModal(code);
        }

        async function openTrackingModal(orderCode) {
            var modal = document.getElementById('modal-order-tracking');
            var container = document.getElementById('tracking-content');
            modal.classList.remove('hidden');

            container.innerHTML = '<div class="text-center py-8"><div class="animate-spin size-8 border-4 border-[#391F18] border-t-transparent rounded-full mx-auto mb-3"></div><p class="text-xs text-gray-500">Mengambil data pesanan...</p></div>';

            try {
                var response = await fetch('/api/catalog/orders/' + encodeURIComponent(orderCode));
                var resData = await response.json();

                if (!response.ok || !resData.success) {
                    container.innerHTML = '<div class="text-center py-6"><p class="text-red-600 font-bold text-sm mb-1">Pesanan Tidak Ditemukan</p><p class="text-xs text-gray-500">Kode pesanan <strong>' + orderCode + '</strong> tidak terdaftar di sistem SumberTani.</p><button onclick="closeTrackingModal()" class="mt-4 px-4 py-2 bg-gray-100 rounded-lg text-xs font-bold text-gray-700">Tutup</button></div>';
                    return;
                }

                var o = resData.data;

                var badgeClass = 'bg-gray-100 text-gray-700';
                var statusLabel = 'Menunggu Konfirmasi';
                if (o.status === 'pending') {
                    badgeClass = 'bg-amber-100 text-amber-800 border border-amber-300';
                    statusLabel = 'Pending (Menunggu Konfirmasi Admin)';
                } else if (o.status === 'confirmed') {
                    badgeClass = 'bg-blue-100 text-blue-800 border border-blue-300';
                    statusLabel = 'Dikonfirmasi (Pesanan Diterima)';
                } else if (o.status === 'processing') {
                    badgeClass = 'bg-indigo-100 text-indigo-800 border border-indigo-300';
                    statusLabel = 'Sedang Diproses';
                } else if (o.status === 'completed') {
                    badgeClass = 'bg-emerald-100 text-emerald-800 border border-emerald-300';
                    statusLabel = 'Selesai (Transaksi Berhasil)';
                } else if (o.status === 'cancelled') {
                    badgeClass = 'bg-red-100 text-red-800 border border-red-300';
                    statusLabel = 'Dibatalkan';
                }

                var itemsHtml = '';
                if (o.items && o.items.length) {
                    itemsHtml = o.items.map(function(item) {
                        return '<div class="flex justify-between items-center py-2 border-b border-gray-100 text-xs">' +
                               '<div><p class="font-bold text-gray-800">' + item.product_name + '</p><p class="text-gray-500">' + item.quantity + ' unit × Rp ' + Number(item.price_snapshot).toLocaleString('id-ID') + '</p></div>' +
                               '<div class="font-bold text-gray-900">Rp ' + Number(item.subtotal).toLocaleString('id-ID') + '</div>' +
                               '</div>';
                    }).join('');
                }

                container.innerHTML = 
                    '<div class="text-center pb-4 border-b border-gray-100">' +
                        '<span class="text-xs font-mono text-gray-400 block mb-1">Kode Pesanan</span>' +
                        '<h4 class="text-xl font-black text-gray-900 font-mono tracking-wide">' + o.order_code + '</h4>' +
                        '<div class="mt-2 inline-block px-3 py-1 rounded-full text-xs font-bold ' + badgeClass + '">' + statusLabel + '</div>' +
                    '</div>' +
                    '<div class="py-3 text-xs space-y-1.5 bg-gray-50 p-3 rounded-xl border border-gray-200">' +
                        '<p class="text-gray-600"><span class="font-semibold text-gray-800">Nama:</span> ' + o.customer_name + '</p>' +
                        '<p class="text-gray-600"><span class="font-semibold text-gray-800">No. Kontak:</span> ' + o.customer_phone + '</p>' +
                        '<p class="text-gray-600"><span class="font-semibold text-gray-800">Alamat:</span> <span class="italic text-gray-500">' + o.customer_address + '</span></p>' +
                        (o.notes ? '<p class="text-gray-600"><span class="font-semibold text-gray-800">Catatan:</span> ' + o.notes + '</p>' : '') +
                    '</div>' +
                    '<div>' +
                        '<h5 class="text-xs font-bold text-gray-700 uppercase mb-2">Rincian Item</h5>' +
                        '<div class="bg-white rounded-lg">' + itemsHtml + '</div>' +
                    '</div>' +
                    '<div class="pt-2 flex justify-between items-center text-sm font-bold border-t border-gray-200">' +
                        '<span>Total Biaya:</span>' +
                        '<span class="text-emerald-700 font-black text-base">Rp ' + Number(o.total_amount).toLocaleString('id-ID') + '</span>' +
                    '</div>' +
                    '<button onclick="closeTrackingModal()" class="w-full mt-4 py-2.5 bg-[#391F18] text-[#e3cba8] font-bold rounded-xl text-xs hover:bg-[#522c22] transition-all">Tutup</button>';
            } catch (e) {
                container.innerHTML = '<div class="text-center py-6 text-red-600 text-xs">Gagal memuat status: ' + e.message + '</div>';
            }
        }
    </script>

    <!-- MODAL 1: CHECKOUT PESANAN PRODUK OLAHAN -->
    <div id="modal-order-checkout" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
        <div class="bg-white text-gray-900 w-full max-w-lg rounded-2xl border-2 border-[#391F18] shadow-[8px_8px_0px_0px_#391F18] overflow-hidden flex flex-col max-h-[90vh]">
            <!-- Header -->
            <div class="bg-[#391F18] text-[#e3cba8] px-6 py-4 flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <span class="w-3 h-3 rounded-full bg-[#25D366]"></span>
                    <h3 class="font-bold text-base">Formulir Pesanan Produk Olahan</h3>
                </div>
                <button type="button" onclick="closeOrderModal()" class="text-white/70 hover:text-white text-lg font-bold">✕</button>
            </div>

            <!-- Body -->
            <form id="form-order-checkout" onsubmit="event.preventDefault(); submitOrderCheckout();" class="p-6 overflow-y-auto space-y-4">
                <input type="hidden" id="order-product-id">
                <input type="hidden" id="order-product-price">
                <input type="hidden" id="order-product-name">
                <input type="hidden" id="order-product-farmer">

                <!-- Product Summary Card -->
                <div class="bg-amber-50/80 p-3.5 rounded-xl border border-amber-200 text-xs text-gray-700 flex justify-between items-center">
                    <div>
                        <p class="font-bold text-sm text-gray-900" id="order-summary-name">Nama Produk</p>
                        <p class="text-gray-500">Petani: <span id="order-summary-farmer" class="font-semibold text-primary">Nama Petani</span></p>
                    </div>
                    <div class="text-right">
                        <span class="block text-primary font-bold text-sm" id="order-summary-price">Rp 0</span>
                        <span class="text-gray-500" id="order-summary-stock">Tersedia: 0 unit</span>
                    </div>
                </div>

                <!-- Nama Lengkap -->
                <div>
                    <label class="block text-xs font-bold text-gray-700 mb-1">Nama Pemesan <span class="text-red-500">*</span></label>
                    <input type="text" id="order-customer-name" required placeholder="Contoh: Budi Santoso" class="w-full px-3.5 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary">
                </div>

                <!-- Nomor WhatsApp -->
                <div>
                    <label class="block text-xs font-bold text-gray-700 mb-1">Nomor WhatsApp / HP <span class="text-red-500">*</span></label>
                    <input type="tel" id="order-customer-phone" required placeholder="Contoh: 081234567890" class="w-full px-3.5 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary">
                    <span class="text-[11px] text-gray-500">Akan digunakan Super Admin untuk konfirmasi pesanan.</span>
                </div>

                <!-- Jumlah Unit -->
                <div>
                    <label class="block text-xs font-bold text-gray-700 mb-1">Jumlah Pesanan (Unit) <span class="text-red-500">*</span></label>
                    <div class="flex items-center gap-3">
                        <button type="button" onclick="adjustOrderQty(-1)" class="w-9 h-9 rounded-lg border border-gray-300 font-bold bg-gray-100 hover:bg-gray-200">-</button>
                        <input type="number" id="order-quantity" value="1" min="1" oninput="calculateOrderTotal()" class="w-20 text-center font-bold px-2 py-1.5 rounded-lg border border-gray-300 text-sm">
                        <button type="button" onclick="adjustOrderQty(1)" class="w-9 h-9 rounded-lg border border-gray-300 font-bold bg-gray-100 hover:bg-gray-200">+</button>
                        <span class="text-xs text-gray-500" id="order-max-stock-hint">Maksimal: 0 unit</span>
                    </div>
                </div>

                <!-- Alamat Pengiriman -->
                <div>
                    <label class="block text-xs font-bold text-gray-700 mb-1">Alamat Pengiriman</label>
                    <textarea id="order-customer-address" rows="2" placeholder="Nama jalan, RT/RW, kelurahan, kecamatan, kota/kabupaten..." class="w-full px-3.5 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary"></textarea>
                </div>

                <!-- Catatan Tambahan -->
                <div>
                    <label class="block text-xs font-bold text-gray-700 mb-1">Catatan Pesanan (Opsional)</label>
                    <input type="text" id="order-notes" placeholder="Contoh: Tolong bungkus ekstra aman..." class="w-full px-3.5 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary">
                </div>

                <!-- Total Estimasi -->
                <div class="bg-emerald-50 p-4 rounded-xl border border-emerald-200 flex justify-between items-center">
                    <span class="text-xs font-bold text-emerald-900 uppercase">Estimasi Total</span>
                    <span class="text-lg font-black text-emerald-800" id="order-total-display">Rp 0</span>
                </div>

                <div id="order-error-message" class="hidden text-xs text-red-600 bg-red-50 p-2.5 rounded-lg border border-red-200"></div>

                <!-- Actions -->
                <div class="pt-2 flex items-center justify-end gap-3 border-t border-gray-100">
                    <button type="button" onclick="closeOrderModal()" class="px-4 py-2 text-xs font-bold text-gray-600 hover:text-gray-800">Batal</button>
                    <button type="submit" id="btn-submit-order" class="px-5 py-2.5 bg-[#25D366] hover:bg-[#20ba59] text-white text-xs font-bold rounded-xl border-2 border-[#1E3A2A] shadow-[2px_2px_0px_0px_#1E3A2A] transition-all flex items-center gap-1.5">
                        <span>Pesan & Lanjut WhatsApp</span>
                        <svg xmlns="http://www.w3.org/2000/svg" class="size-4 fill-current" viewBox="0 0 24 24"><path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.582 2.128 2.182-.573c.978.58 1.911.928 3.145.929 3.178 0 5.767-2.587 5.768-5.766.001-3.187-2.575-5.77-5.764-5.771zm3.392 8.244c-.144.405-.837.774-1.17.824-.299.045-.677.063-1.092-.069-.252-.08-.575-.187-.988-.365-1.739-.751-2.874-2.502-2.961-2.617-.087-.116-.708-.94-.708-1.793s.448-1.273.607-1.446c.159-.173.346-.217.462-.217l.332.006c.106.005.249-.04.39.298.144.347.491 1.2.534 1.287.043.087.072.188.014.304-.058.116-.087.188-.173.289l-.26.304c-.087.086-.177.18-.076.354.101.174.449.741.964 1.201.662.591 1.221.774 1.394.86s.275.072.376-.043c.101-.116.433-.506.549-.68.116-.173.231-.145.39-.087s1.011.477 1.184.564.289.13.332.202c.045.072.045.419-.1.824zm-3.423-14.416c-6.627 0-12 5.373-12 12 0 2.159.57 4.187 1.564 5.946l-1.662 6.075 6.221-1.632c1.701.928 3.652 1.459 5.727 1.459 6.627 0 12-5.373 12-12 0-6.627-5.373-12-12-12z"/></svg>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- MODAL 2: DETAIL STATUS PELACAKAN PESANAN (PUBLIC TRACKING) -->
    <div id="modal-order-tracking" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
        <div class="bg-white text-gray-900 w-full max-w-md rounded-2xl border-2 border-[#391F18] shadow-[8px_8px_0px_0px_#391F18] overflow-hidden flex flex-col max-h-[90vh]">
            <div class="bg-[#391F18] text-[#e3cba8] px-6 py-4 flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <span class="w-3 h-3 rounded-full bg-blue-400"></span>
                    <h3 class="font-bold text-base">Status Pelacakan Pesanan</h3>
                </div>
                <button type="button" onclick="closeTrackingModal()" class="text-white/70 hover:text-white text-lg font-bold">✕</button>
            </div>

            <div id="tracking-content" class="p-6 overflow-y-auto space-y-4">
                <!-- Injected via JS -->
            </div>
        </div>
    </div>
</body>
</html>
