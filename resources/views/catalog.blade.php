<!DOCTYPE html>
<html lang="id" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Katalog Produk Olahan - SumberTani Berbasis AI</title>
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
        @keyframes blob {
            0% { transform: translate(0px, 0px) scale(1) rotate(0deg); }
            33% { transform: translate(15vw, -15vh) scale(1.2) rotate(90deg); }
            66% { transform: translate(-20vw, 20vh) scale(0.8) rotate(180deg); }
            100% { transform: translate(0px, 0px) scale(1) rotate(360deg); }
        }
        .animate-blob {
            animation: blob 20s infinite alternate ease-in-out;
        }
    </style>
</head>
<body class="relative min-h-screen text-gray-800 font-sans selection:bg-secondary selection:text-white bg-[#1E3A2A]">

    <!-- Background Elements -->
    <div class="fixed inset-0 z-[-1] w-full h-full overflow-hidden pointer-events-none">
        <div class="absolute top-[-10%] left-[-10%] w-[50vw] h-[50vw] rounded-full bg-[#cbb29b]/15 filter blur-[120px] animate-blob"></div>
        <div class="absolute bottom-[-10%] right-[-10%] w-[50vw] h-[50vw] rounded-full bg-[#8d5d47]/25 filter blur-[120px] animate-blob" style="animation-delay: 4s;"></div>
    </div>

    <!-- 1. NAVBAR -->
    <nav class="sticky top-0 backdrop-blur-md bg-[#A39987]/90 border-b border-[#5D3A2F]/50 px-4 sm:px-8 py-3.5 mx-auto w-full z-50">
        <div class="max-w-7xl mx-auto w-full flex justify-between items-center">
            <!-- Brand & Return Link -->
            <div class="flex items-center gap-3">
                <a href="{{ route('landing') }}" class="flex items-center gap-3 group">
                    <div class="w-10 h-10 rounded-xl overflow-hidden shadow-inner shadow-black/30 bg-white ring-1 ring-white/20 p-1 flex items-center justify-center">
                        <img src="{{ asset('images/logo.png') }}" alt="Logo SumberTani" class="w-full h-full object-contain">
                    </div>
                    <div>
                        <h1 class="text-lg font-bold leading-none text-white tracking-tight group-hover:text-[#e3cba8] transition">SumberTani</h1>
                        <p class="text-[9px] text-white/75 font-semibold tracking-wider uppercase mt-1">Katalog Publik</p>
                    </div>
                </a>
            </div>

            <!-- Nav Links -->
            <div class="flex items-center gap-2 sm:gap-4">
                <a href="{{ route('landing') }}" class="inline-flex items-center gap-1.5 text-xs sm:text-sm font-semibold text-white/90 hover:text-white px-3 py-2 rounded-xl hover:bg-white/10 transition">
                    <svg xmlns="http://www.w3.org/2000/svg" class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                    </svg>
                    <span>Beranda</span>
                </a>

                <a href="#tracking-section" class="inline-flex items-center gap-1.5 text-xs sm:text-sm font-semibold text-[#e3cba8] hover:text-white px-3 py-2 rounded-xl hover:bg-white/10 transition">
                    <svg xmlns="http://www.w3.org/2000/svg" class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                    <span>Lacak Pesanan</span>
                </a>

                <button onclick="handleAppRouting(event)" class="text-xs sm:text-sm font-bold text-white bg-primary hover:bg-primary-dark transition px-4 sm:px-5 py-2 rounded-xl border-2 border-[#391F18] shadow-[3px_3px_0px_0px_#391F18] hover:shadow-[5px_5px_0px_0px_#391F18] hover:-translate-y-0.5 flex items-center gap-1.5">
                    <span>Aplikasi</span>
                    <svg xmlns="http://www.w3.org/2000/svg" class="size-3.5 sm:size-4" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M3 3a1 1 0 011 1v12a1 1 0 11-2 0V4a1 1 0 011-1zm7.707 3.293a1 1 0 010 1.414L9.414 9H17a1 1 0 110 2H9.414l1.293 1.293a1 1 0 01-1.414 1.414l-3-3a1 1 0 010-1.414l3-3a1 1 0 011.414 0z" clip-rule="evenodd" />
                    </svg>
                </button>
            </div>
        </div>
    </nav>

    <!-- 2. HEADER BANNER -->
    <header class="w-full py-12 px-4 text-center text-white relative">
        <div class="max-w-4xl mx-auto">
            <div class="inline-flex items-center gap-2 px-4 py-1.5 bg-[#e3cba8] border-2 border-[#391F18] shadow-[2px_2px_0px_0px_#391F18] rounded-full text-xs font-bold text-[#391F18] uppercase tracking-wide mb-4">
                <span>🌾 Etalase Produk Petani Lokal</span>
            </div>
            <h1 class="text-3xl sm:text-4xl md:text-5xl font-heading font-black text-[#e3cba8] leading-tight">
                Katalog Produk Olahan Tani
            </h1>
            <p class="mt-3 text-white/80 max-w-2xl mx-auto text-sm sm:text-base leading-relaxed">
                Dukung kemandirian pangan dan hilirisasi petani lokal. Beli aneka produk olahan bermutu tinggi langsung dari mitra kelompok tani binaan SumberTani.
            </p>

            <!-- Search & Filters Container -->
            <div class="mt-8 max-w-3xl mx-auto bg-white/10 backdrop-blur-md p-4 sm:p-5 rounded-2xl border-2 border-[#e3cba8]/40 shadow-xl">
                <form action="{{ route('catalog') }}" method="GET" class="flex flex-col sm:flex-row gap-3">
                    <!-- Search Input -->
                    <div class="relative flex-1">
                        <span class="absolute inset-y-0 left-0 flex items-center pl-3.5 pointer-events-none text-white/50">
                            <svg xmlns="http://www.w3.org/2000/svg" class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                            </svg>
                        </span>
                        <input type="text" name="search" value="{{ $search ?? '' }}" placeholder="Cari nama produk olahan (contoh: Keripik, Tepung...)" class="w-full pl-10 pr-4 py-2.5 rounded-xl bg-black/25 border border-white/20 text-white placeholder-white/50 focus:outline-none focus:border-[#e3cba8] text-sm">
                    </div>

                    <!-- Status Filter Dropdown / Pills -->
                    <select name="status" class="px-4 py-2.5 rounded-xl bg-black/25 border border-white/20 text-white focus:outline-none focus:border-[#e3cba8] text-sm cursor-pointer">
                        <option value="" class="bg-gray-800 text-white" {{ empty($statusFilter) ? 'selected' : '' }}>Semua Status</option>
                        <option value="active" class="bg-gray-800 text-white" {{ ($statusFilter ?? '') === 'active' ? 'selected' : '' }}>Tersedia Saja</option>
                        <option value="out_of_stock" class="bg-gray-800 text-white" {{ ($statusFilter ?? '') === 'out_of_stock' ? 'selected' : '' }}>Stok Habis Saja</option>
                    </select>

                    <button type="submit" class="px-6 py-2.5 bg-[#e3cba8] hover:bg-white text-[#391F18] font-bold rounded-xl text-sm transition-all shadow-[2px_2px_0px_0px_#000] flex items-center justify-center gap-1.5">
                        <span>Cari</span>
                    </button>

                    @if(!empty($search) || !empty($statusFilter))
                        <a href="{{ route('catalog') }}" class="px-4 py-2.5 bg-white/20 hover:bg-white/30 text-white font-semibold rounded-xl text-sm transition-all flex items-center justify-center">
                            Reset
                        </a>
                    @endif
                </form>
            </div>
        </div>
    </header>

    <!-- 3. PRODUCT LISTING GRID -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-20">
        @if(isset($products) && count($products) > 0)
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 sm:gap-8">
                @foreach($products as $product)
                    @php
                        $isOutOfStock = $product->status === 'out_of_stock' || $product->stock <= 0;
                        $cleanPhone = preg_replace('/[^0-9]/', '', $superAdminPhone ?? '6281234567890');
                        if (str_starts_with($cleanPhone, '0')) {
                            $cleanPhone = '62' . substr($cleanPhone, 1);
                        }
                        $farmerDisplayName = $product->owner?->farm_name ?? $product->owner?->name ?? 'Mitra Petani';
                    @endphp
                    <div class="bg-white rounded-2xl border-2 border-[#391F18] shadow-[5px_5px_0px_0px_#391F18] overflow-hidden flex flex-col justify-between hover:-translate-y-1.5 transition-all duration-300 group text-left">
                        <!-- Product Thumbnail -->
                        <div class="relative w-full h-52 bg-[#e3cba8]/20 overflow-hidden flex items-center justify-center border-b-2 border-[#391F18] cursor-pointer" onclick="openDetailModal({{ $product->id }}, '{{ addslashes($product->name) }}', {{ (float) $product->price }}, {{ (int) $product->stock }}, '{{ addslashes($farmerDisplayName) }}', '{{ addslashes($product->description ?? '') }}', '{{ $product->photo_url ?? '' }}', '{{ $product->unit ?? 'unit' }}')">
                            @if($product->photo_url)
                                <img src="{{ $product->photo_url }}" alt="{{ $product->name }}" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500">
                            @else
                                <div class="flex flex-col items-center justify-center text-[#5D3A2F]/60 gap-2">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-14">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
                                    </svg>
                                    <span class="text-xs font-bold uppercase tracking-wider">Foto Produk</span>
                                </div>
                            @endif

                            <!-- Stock Status Badge -->
                            <div class="absolute top-3 right-3">
                                @if($isOutOfStock)
                                    <span class="inline-flex items-center gap-1.5 bg-amber-500 text-white text-xs font-bold px-3 py-1 rounded-full shadow-md">
                                        <span class="w-2 h-2 rounded-full bg-white animate-pulse"></span>
                                        Stok Habis
                                    </span>
                                @else
                                    <span class="inline-flex items-center gap-1.5 bg-emerald-600 text-white text-xs font-bold px-3 py-1 rounded-full shadow-md">
                                        <span class="w-2 h-2 rounded-full bg-white animate-pulse"></span>
                                        Tersedia ({{ $product->stock }})
                                    </span>
                                @endif
                            </div>
                        </div>

                        <!-- Card Body -->
                        <div class="p-5 flex-1 flex flex-col justify-between">
                            <div>
                                <!-- Farmer Owner -->
                                <div class="flex items-center justify-between text-xs text-gray-500 mb-1.5">
                                    <span class="font-bold text-primary flex items-center gap-1">
                                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-3.5 h-3.5">
                                            <path fill-rule="evenodd" d="M10 9a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm-7 9a7 7 0 1 1 14 0H3Z" clip-rule="evenodd" />
                                        </svg>
                                        {{ $farmerDisplayName }}
                                    </span>
                                    <span class="font-semibold text-gray-600 bg-gray-100 px-2 py-0.5 rounded text-[11px]">
                                        {{ $product->unit ?? 'Unit' }}
                                    </span>
                                </div>

                                <!-- Product Title -->
                                <h2 class="text-lg font-bold text-gray-900 leading-snug mb-1.5 group-hover:text-primary transition-colors cursor-pointer" onclick="openDetailModal({{ $product->id }}, '{{ addslashes($product->name) }}', {{ (float) $product->price }}, {{ (int) $product->stock }}, '{{ addslashes($farmerDisplayName) }}', '{{ addslashes($product->description ?? '') }}', '{{ $product->photo_url ?? '' }}', '{{ $product->unit ?? 'unit' }}')">
                                    {{ $product->name }}
                                </h2>

                                <!-- Description -->
                                <p class="text-gray-600 text-xs line-clamp-2 mb-4">
                                    {{ $product->description ?: 'Produk olahan bermutu tinggi dari hasil panen petani binaan SumberTani.' }}
                                </p>
                            </div>

                            <!-- Footer Price & Buttons -->
                            <div class="pt-3 border-t border-gray-100 flex items-center justify-between mt-auto">
                                <div>
                                    <span class="text-[10px] text-gray-400 block font-medium uppercase">Harga</span>
                                    <span class="text-base sm:text-lg font-extrabold text-[#2d6a4f]">
                                        Rp {{ number_format($product->price, 0, ',', '.') }}
                                    </span>
                                </div>

                                <div class="flex items-center gap-1.5">
                                    <!-- Detail Button -->
                                    <button type="button" onclick="openDetailModal({{ $product->id }}, '{{ addslashes($product->name) }}', {{ (float) $product->price }}, {{ (int) $product->stock }}, '{{ addslashes($farmerDisplayName) }}', '{{ addslashes($product->description ?? '') }}', '{{ $product->photo_url ?? '' }}', '{{ $product->unit ?? 'unit' }}')" class="p-2 rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-700 transition" title="Lihat Rincian Produk">
                                        <svg xmlns="http://www.w3.org/2000/svg" class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                    </button>

                                    <!-- Order Button -->
                                    @if($isOutOfStock)
                                        <button disabled class="cursor-not-allowed bg-gray-100 text-gray-400 text-xs font-bold px-3 py-2 rounded-xl border border-gray-300">
                                            Habis
                                        </button>
                                    @else
                                        <button type="button" onclick="openOrderModal({{ $product->id }}, '{{ addslashes($product->name) }}', {{ (float) $product->price }}, {{ (int) $product->stock }}, '{{ addslashes($farmerDisplayName) }}')" class="inline-flex items-center gap-1 bg-[#25D366] hover:bg-[#20ba59] text-white text-xs font-bold px-3 sm:px-3.5 py-2 rounded-xl border-2 border-[#1E3A2A] shadow-[2px_2px_0px_0px_#1E3A2A] hover:shadow-[3px_3px_0px_0px_#1E3A2A] hover:-translate-y-0.5 transition-all">
                                            <span>Pesan</span>
                                        </button>
                                    @endif
                                </div>
                            </div>
                        </div>
                    </div>
                @endforeach
            </div>

            <!-- Pagination Links if available -->
            @if(method_exists($products, 'hasPages') && $products->hasPages())
                <div class="mt-12 flex justify-center">
                    {{ $products->links() }}
                </div>
            @endif
        @else
            <!-- Empty State -->
            <div class="bg-white/10 backdrop-blur-md rounded-2xl border-2 border-[#e3cba8]/30 p-12 text-center max-w-xl mx-auto text-white">
                <div class="w-16 h-16 mx-auto bg-[#e3cba8]/20 rounded-full flex items-center justify-center text-[#e3cba8] mb-4">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-8">
                        <path stroke-linecap="round" stroke-linejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
                    </svg>
                </div>
                <h3 class="text-xl font-bold text-white mb-2">Tidak Ada Produk Ditemukan</h3>
                <p class="text-white/70 text-sm leading-relaxed mb-6">
                    @if(!empty($search))
                        Tidak ada produk olahan yang cocok dengan kata kunci "{{ $search }}". Coba cari kata kunci lain.
                    @else
                        Saat ini katalog produk sedang dalam persiapan oleh mitra kelompok tani kami.
                    @endif
                </p>
                <a href="{{ route('catalog') }}" class="inline-flex items-center gap-2 px-5 py-2.5 bg-[#e3cba8] text-[#391F18] font-bold rounded-xl text-sm transition">
                    Lihat Semua Produk
                </a>
            </div>
        @endif

        <!-- 4. TRACKING PESANAN PUBLIK SECTION -->
        <section id="tracking-section" class="mt-20 max-w-3xl mx-auto bg-[#391F18]/85 backdrop-blur-md border-2 border-[#e3cba8]/40 rounded-2xl p-6 sm:p-8 shadow-2xl text-center text-white">
            <div class="inline-flex items-center gap-2 text-xs font-bold text-[#e3cba8] uppercase tracking-wider mb-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="size-4 text-[#e3cba8]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                Lacak Status Pesanan Publik
            </div>
            <h3 class="text-xl sm:text-2xl font-bold text-white mb-2">Cek Progres Pesanan Anda</h3>
            <p class="text-white/70 text-xs sm:text-sm mb-6 max-w-md mx-auto">
                Masukkan kode pesanan yang Anda terima saat pemesanan (contoh: <span class="font-mono text-[#e3cba8]">ORD-20260925-XXXX</span>) untuk memantau status secara langsung.
            </p>
            <form onsubmit="event.preventDefault(); trackOrderFromInput();" class="flex flex-col sm:flex-row gap-2 max-w-lg mx-auto">
                <input type="text" id="landing-tracking-input" placeholder="Masukkan Kode Pesanan..." required class="flex-1 px-4 py-2.5 rounded-xl bg-white/10 border border-[#e3cba8]/40 text-white placeholder-white/40 focus:outline-none focus:border-[#e3cba8] text-sm font-mono uppercase">
                <button type="submit" class="px-6 py-2.5 bg-[#e3cba8] hover:bg-white text-[#391F18] font-bold rounded-xl text-sm transition-all shadow-[2px_2px_0px_0px_#000]">
                    Lacak Sekarang
                </button>
            </form>
        </section>
    </main>

    <!-- 5. FOOTER -->
    <footer class="bg-[#152a1e] text-white/75 py-10 border-t border-white/10 text-xs text-center">
        <div class="max-w-7xl mx-auto px-4 space-y-4">
            <div class="flex items-center justify-center gap-3">
                <img src="{{ asset('images/logo.png') }}" alt="Logo" class="w-6 h-6 object-contain">
                <span class="font-bold text-white text-sm">SumberTani Berbasis AI</span>
            </div>
            <p class="text-white/60 max-w-lg mx-auto">
                Platform hilirisasi dan digitalisasi agribisnis kemitraan kelompok tani binaan PKM-Kosabangsa.
            </p>
            <div class="flex items-center justify-center gap-6 font-medium text-white/80 pt-2">
                <a href="{{ route('landing') }}" class="hover:text-white transition">Beranda</a>
                <a href="{{ route('catalog') }}" class="hover:text-white transition">Katalog Produk</a>
                <a href="#tracking-section" class="hover:text-white transition">Lacak Pesanan</a>
            </div>
            <p class="text-[11px] text-white/40 pt-4">&copy; {{ date('Y') }} SumberTani. Hak Cipta Dilindungi Undang-Undang.</p>
        </div>
    </footer>

    <!-- MODAL 1: DETAIL PRODUK -->
    <div id="modal-product-detail" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
        <div class="bg-white text-gray-900 w-full max-w-md rounded-2xl border-2 border-[#391F18] shadow-[8px_8px_0px_0px_#391F18] overflow-hidden flex flex-col max-h-[90vh]">
            <div class="bg-[#391F18] text-[#e3cba8] px-5 py-3.5 flex items-center justify-between">
                <h3 class="font-bold text-sm" id="detail-modal-title">Rincian Produk</h3>
                <button type="button" onclick="closeDetailModal()" class="text-white/70 hover:text-white text-lg font-bold">✕</button>
            </div>
            <div class="p-5 overflow-y-auto space-y-4 text-left">
                <div class="w-full h-52 bg-gray-100 rounded-xl overflow-hidden flex items-center justify-center border border-gray-200">
                    <img id="detail-modal-image" src="" alt="Foto Produk" class="w-full h-full object-cover">
                </div>
                <div>
                    <span id="detail-modal-badge" class="inline-flex text-[11px] font-bold px-2.5 py-0.5 rounded-full mb-2"></span>
                    <h2 id="detail-modal-name" class="text-xl font-bold text-gray-900 leading-snug"></h2>
                    <p class="text-xs text-gray-500 mt-1">Petani/Poktan: <span id="detail-modal-farmer" class="font-bold text-primary"></span></p>
                </div>
                <div class="bg-amber-50/80 p-3.5 rounded-xl border border-amber-200 flex justify-between items-center text-xs">
                    <span class="text-gray-600 font-medium">Harga Satuan</span>
                    <span id="detail-modal-price" class="text-base font-extrabold text-primary"></span>
                </div>
                <div>
                    <h4 class="text-xs font-bold text-gray-700 uppercase tracking-wider mb-1">Deskripsi Produk</h4>
                    <p id="detail-modal-desc" class="text-xs text-gray-600 leading-relaxed"></p>
                </div>
                <div class="pt-3 border-t border-gray-100 flex items-center justify-end gap-3">
                    <button type="button" onclick="closeDetailModal()" class="px-4 py-2 text-xs font-bold text-gray-600 hover:text-gray-800">Tutup</button>
                    <button type="button" id="btn-detail-order" class="px-5 py-2.5 bg-[#25D366] hover:bg-[#20ba59] text-white text-xs font-bold rounded-xl border-2 border-[#1E3A2A] shadow-[2px_2px_0px_0px_#1E3A2A] transition">
                        Pesan Sekarang
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL 2: CHECKOUT PESANAN PRODUK OLAHAN -->
    <div id="modal-order-checkout" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
        <div class="bg-white text-gray-900 w-full max-w-lg rounded-2xl border-2 border-[#391F18] shadow-[8px_8px_0px_0px_#391F18] overflow-hidden flex flex-col max-h-[90vh]">
            <div class="bg-[#391F18] text-[#e3cba8] px-6 py-4 flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <span class="w-3 h-3 rounded-full bg-[#25D366]"></span>
                    <h3 class="font-bold text-base">Formulir Pesanan Produk Olahan</h3>
                </div>
                <button type="button" onclick="closeOrderModal()" class="text-white/70 hover:text-white text-lg font-bold">✕</button>
            </div>

            <form id="form-order-checkout" onsubmit="event.preventDefault(); submitOrderCheckout();" class="p-6 overflow-y-auto space-y-4 text-left">
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

    <!-- MODAL 3: STATUS PELACAKAN PESANAN -->
    <div id="modal-order-tracking" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
        <div class="bg-white text-gray-900 w-full max-w-md rounded-2xl border-2 border-[#391F18] shadow-[8px_8px_0px_0px_#391F18] overflow-hidden flex flex-col max-h-[90vh]">
            <div class="bg-[#391F18] text-[#e3cba8] px-6 py-4 flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <span class="w-3 h-3 rounded-full bg-blue-400"></span>
                    <h3 class="font-bold text-base">Status Pelacakan Pesanan</h3>
                </div>
                <button type="button" onclick="closeTrackingModal()" class="text-white/70 hover:text-white text-lg font-bold">✕</button>
            </div>

            <div id="tracking-content" class="p-6 overflow-y-auto space-y-4 text-left">
                <!-- Injected via JS -->
            </div>
        </div>
    </div>

    <!-- CLIENT JAVASCRIPT LOGIC -->
    <script>
        var currentMaxStock = 0;
        var superAdminPhone = '{{ preg_replace("/[^0-9]/", "", $superAdminPhone ?? "6281234567890") }}';
        if (superAdminPhone.startsWith('0')) {
            superAdminPhone = '62' + superAdminPhone.substring(1);
        }

        // App Routing Handler
        function handleAppRouting(e) {
            e.preventDefault();
            var port = window.location.port ? ':' + window.location.port : '';
            window.location.href = window.location.protocol + '//' + window.location.hostname + port + '/app';
        }

        // ─── Detail Modal ───────────────────────────────────────────────────
        function openDetailModal(id, name, price, stock, farmer, desc, photoUrl, unit) {
            document.getElementById('detail-modal-name').textContent = name;
            document.getElementById('detail-modal-farmer').textContent = farmer;
            document.getElementById('detail-modal-price').textContent = 'Rp ' + Number(price).toLocaleString('id-ID') + ' / ' + unit;
            document.getElementById('detail-modal-desc').textContent = desc || 'Produk olahan bermutu tinggi dari hasil panen petani binaan SumberTani.';
            
            var imgEl = document.getElementById('detail-modal-image');
            if (photoUrl) {
                imgEl.src = photoUrl;
                imgEl.classList.remove('hidden');
            } else {
                imgEl.src = '{{ asset("images/logo.png") }}';
            }

            var badgeEl = document.getElementById('detail-modal-badge');
            var btnOrder = document.getElementById('btn-detail-order');
            if (stock <= 0) {
                badgeEl.className = 'inline-flex text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-amber-100 text-amber-800 mb-2';
                badgeEl.textContent = 'Stok Habis';
                btnOrder.disabled = true;
                btnOrder.className = 'px-5 py-2.5 bg-gray-200 text-gray-400 cursor-not-allowed text-xs font-bold rounded-xl';
                btnOrder.textContent = 'Stok Habis';
            } else {
                badgeEl.className = 'inline-flex text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 mb-2';
                badgeEl.textContent = 'Tersedia (' + stock + ' ' + unit + ')';
                btnOrder.disabled = false;
                btnOrder.className = 'px-5 py-2.5 bg-[#25D366] hover:bg-[#20ba59] text-white text-xs font-bold rounded-xl border-2 border-[#1E3A2A] shadow-[2px_2px_0px_0px_#1E3A2A] transition';
                btnOrder.textContent = 'Pesan Sekarang';
                btnOrder.onclick = function() {
                    closeDetailModal();
                    openOrderModal(id, name, price, stock, farmer);
                };
            }

            document.getElementById('modal-product-detail').classList.remove('hidden');
        }

        function closeDetailModal() {
            document.getElementById('modal-product-detail').classList.add('hidden');
        }

        // ─── Order Checkout Modal ───────────────────────────────────────────
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
                        items: [
                            {
                                processed_product_id: productId,
                                quantity: qty
                            }
                        ]
                    })
                });

                var data = await response.json();

                if (!response.ok) {
                    throw new Error(data.message || 'Gagal menyimpan pesanan. Silakan periksa kembali formulir.');
                }

                var order = data.data || data;
                var orderCode = order.order_code || 'ORD-NEW';
                var totalAmount = (price * qty);

                var waText = "Halo Admin SumberTani,%0A" +
                    "Saya telah membuat pesanan baru melalui Katalog Publik SumberTani:%0A%0A" +
                    "*Kode Pesanan:* " + orderCode + "%0A" +
                    "*Produk:* " + encodeURIComponent(productName) + "%0A" +
                    "*Petani:* " + encodeURIComponent(farmerName) + "%0A" +
                    "*Jumlah:* " + qty + " unit%0A" +
                    "*Total Harga:* Rp " + Number(totalAmount).toLocaleString('id-ID') + "%0A%0A" +
                    "*Nama Pemesan:* " + encodeURIComponent(customerName) + "%0A" +
                    "*Nomor HP:* " + encodeURIComponent(customerPhone) + "%0A" +
                    "*Alamat Pengiriman:* " + encodeURIComponent(customerAddress || '-') + "%0A" +
                    (notes ? ("*Catatan:* " + encodeURIComponent(notes) + "%0A") : "") + "%0A" +
                    "Mohon bantuan untuk konfirmasi ketersediaan dan detail pembayarannya. Terima kasih!";

                closeOrderModal();

                var waUrl = "https://wa.me/" + superAdminPhone + "?text=" + waText;
                window.open(waUrl, '_blank');

                alert('Pesanan berhasil dibuat dengan kode: ' + orderCode + '\nAnda dialihkan ke WhatsApp resmi Super Admin untuk konfirmasi pembayaran.');
            } catch (e) {
                errEl.textContent = e.message || 'Terjadi kesalahan sistem. Coba lagi.';
                errEl.classList.remove('hidden');
            } finally {
                btn.disabled = false;
                btn.innerHTML = '<span>Pesan & Lanjut WhatsApp</span>';
            }
        }

        // ─── Public Order Tracking ──────────────────────────────────────────
        function trackOrderFromInput() {
            var code = document.getElementById('landing-tracking-input').value.trim();
            if (!code) return;
            openTrackingModal(code);
        }

        function closeTrackingModal() {
            document.getElementById('modal-order-tracking').classList.add('hidden');
        }

        async function openTrackingModal(orderCode) {
            var modal = document.getElementById('modal-order-tracking');
            var container = document.getElementById('tracking-content');
            modal.classList.remove('hidden');

            container.innerHTML = '<div class="text-center py-6 text-gray-500 text-xs">Memuat informasi pesanan <span class="font-mono font-bold">' + orderCode + '</span>...</div>';

            try {
                var response = await fetch('/api/catalog/orders/' + encodeURIComponent(orderCode), {
                    headers: { 'Accept': 'application/json' }
                });
                var resData = await response.json();

                if (!response.ok) {
                    throw new Error(resData.message || 'Pesanan tidak ditemukan.');
                }

                var o = resData.data || resData;

                var statusLabels = {
                    'pending': { label: 'Menunggu Konfirmasi', color: 'bg-amber-100 text-amber-800' },
                    'confirmed': { label: 'Pesanan Dikonfirmasi', color: 'bg-blue-100 text-blue-800' },
                    'processing': { label: 'Sedang Diproses', color: 'bg-indigo-100 text-indigo-800' },
                    'shipped': { label: 'Sedang Dikirim', color: 'bg-purple-100 text-purple-800' },
                    'completed': { label: 'Selesai & Diterima', color: 'bg-emerald-100 text-emerald-800' },
                    'cancelled': { label: 'Dibatalkan', color: 'bg-red-100 text-red-800' }
                };

                var st = statusLabels[o.status] || { label: o.status, color: 'bg-gray-100 text-gray-800' };

                var itemsHtml = '';
                if (o.items && o.items.length) {
                    o.items.forEach(function(it) {
                        itemsHtml += '<div class="flex justify-between items-center py-1 border-b border-gray-100 text-xs">' +
                            '<span>' + (it.product_name || 'Produk') + ' (x' + it.quantity + ')</span>' +
                            '<span class="font-bold">Rp ' + Number(it.subtotal || (it.price * it.quantity)).toLocaleString('id-ID') + '</span>' +
                            '</div>';
                    });
                }

                var html = '<div class="space-y-3">' +
                    '<div class="flex items-center justify-between pb-3 border-b border-gray-100">' +
                    '<div>' +
                    '<span class="text-[10px] text-gray-400 uppercase font-bold block">Kode Pesanan</span>' +
                    '<span class="font-mono font-black text-sm text-gray-900">' + o.order_code + '</span>' +
                    '</div>' +
                    '<span class="text-xs font-bold px-2.5 py-1 rounded-full ' + st.color + '">' + st.label + '</span>' +
                    '</div>' +

                    '<div class="text-xs space-y-1 text-gray-600">' +
                    '<div><span class="text-gray-400">Pemesan:</span> <span class="font-bold text-gray-800">' + o.customer_name + '</span></div>' +
                    '<div><span class="text-gray-400">Tanggal:</span> ' + (o.created_at ? o.created_at.substring(0, 10) : '-') + '</div>' +
                    '<div><span class="text-gray-400">Total Tagihan:</span> <span class="font-bold text-primary text-sm">Rp ' + Number(o.total_amount).toLocaleString('id-ID') + '</span></div>' +
                    '</div>' +

                    '<div class="pt-2">' +
                    '<span class="text-[10px] font-bold text-gray-400 uppercase block mb-1">Rincian Barang</span>' +
                    itemsHtml +
                    '</div>' +

                    '<div class="pt-3 text-[11px] text-gray-500 italic bg-gray-50 p-2.5 rounded-lg">' +
                    'Perlu bantuan? Hubungi Super Admin di WhatsApp: <b>' + superAdminPhone + '</b>' +
                    '</div>' +
                    '</div>';

                container.innerHTML = html;
            } catch (e) {
                container.innerHTML = '<div class="text-center py-6 text-red-600 text-xs">Gagal memuat status: ' + e.message + '</div>';
            }
        }
    </script>
</body>
</html>
