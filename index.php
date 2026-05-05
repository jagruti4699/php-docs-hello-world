<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Status | PHP <?php echo phpversion(); ?></title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body class="bg-slate-900 text-slate-200 font-sans min-h-screen flex items-center justify-center p-6">

    <div class="max-w-4xl w-full bg-slate-800 rounded-2xl shadow-2xl overflow-hidden border border-slate-700">
        <!-- Header -->
        <div class="bg-gradient-to-r from-indigo-600 to-violet-600 p-8">
            <div class="flex justify-between items-center">
                <div>
                    <h1 class="text-3xl font-bold text-white tracking-tight">System Info</h1>
                    <p class="text-indigo-100 mt-1">Operational & Updated</p>
                </div>
                <div class="bg-white/20 p-4 rounded-xl backdrop-blur-md">
                    <i class="fa-brands fa-php text-4xl text-white"></i>
                </div>
            </div>
        </div>

        <!-- Grid Content -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 p-8">
            
            <!-- PHP Version -->
            <div class="bg-slate-700/50 p-6 rounded-xl border border-slate-600 hover:border-indigo-500 transition">
                <p class="text-slate-400 text-xs uppercase font-bold tracking-widest mb-1">PHP Version</p>
                <p class="text-2xl font-mono text-indigo-400"><?php echo phpversion(); ?></p>
            </div>

            <!-- Server Software -->
            <div class="bg-slate-700/50 p-6 rounded-xl border border-slate-600 hover:border-indigo-500 transition">
                <p class="text-slate-400 text-xs uppercase font-bold tracking-widest mb-1">Server Engine</p>
                <p class="text-lg truncate"><?php echo $_SERVER['SERVER_SOFTWARE']; ?></p>
            </div>

            <!-- Display Message -->
            <div class="bg-slate-700/50 p-6 rounded-xl border border-slate-600 md:col-span-2">
                <p class="text-slate-400 text-xs uppercase font-bold tracking-widest mb-2">Active Message</p>
                <div class="flex items-center space-x-3 text-emerald-400">
                    <span class="relative flex h-3 w-3">
                        <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                        <span class="relative inline-flex rounded-full h-3 w-3 bg-emerald-500"></span>
                    </span>
                    <p class="text-xl font-medium">"Hello World! morning test"</p>
                </div>
            </div>

            <!-- Quick Stats -->
            <div class="text-sm text-slate-500 italic">
                Server IP: <?php echo $_SERVER['SERVER_ADDR'] ?? '127.0.0.1'; ?>
            </div>
            <div class="text-sm text-slate-500 text-right">
                <?php echo date('Y-m-d H:i:s'); ?>
            </div>

        </div>

        <!-- Footer Link -->
        <div class="bg-slate-900/50 p-4 text-center border-t border-slate-700">
            <a href="?full=1" class="text-xs text-slate-500 hover:text-indigo-400 transition underline">View Full PHP Configuration &rarr;</a>
        </div>
    </div>

    <?php 
    // Secret trigger: add ?full=1 to your URL to see the standard phpinfo
    if (isset($_GET['full'])) {
        echo '<div class="hidden">'; phpinfo(); echo '</div>';
    }
    ?>

</body>
</html>
