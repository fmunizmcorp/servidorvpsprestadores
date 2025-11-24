<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Create New Site') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    
                    @if(session('success'))
                        <div class="mb-4 p-4 bg-green-100 border-l-4 border-green-500 text-green-700">
                            <p class="font-bold">Success!</p>
                            <p>{{ session('success') }}</p>
                        </div>
                    @endif

                    @if($errors->any())
                        <div class="mb-4 p-4 bg-red-100 border-l-4 border-red-500 text-red-700">
                            <p class="font-bold">Error!</p>
                            <ul>
                                @foreach($errors->all() as $error)
                                    <li>{{ $error }}</li>
                                @endforeach
                            </ul>
                        </div>
                    @endif

                    <div id="processing-overlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7); z-index:9999; justify-content:center; align-items:center;">
                        <div style="background:white; padding:40px; border-radius:10px; text-align:center; max-width:500px;">
                            <div style="margin-bottom:20px;">
                                <svg class="animate-spin h-16 w-16 mx-auto text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                </svg>
                            </div>
                            <h3 style="font-size:1.5rem; font-weight:bold; color:#1f2937; margin-bottom:10px;">Creating Site...</h3>
                            <p style="color:#6b7280; margin-bottom:20px;">Site creation is in progress. This process takes approximately <strong>25-30 seconds</strong>.</p>
                            <div style="background:#e5e7eb; height:8px; border-radius:4px; overflow:hidden; margin-bottom:15px;">
                                <div id="progress-bar" style="background:#3b82f6; height:100%; width:0%; transition:width 0.5s;"></div>
                            </div>
                            <p style="color:#9ca3af; font-size:0.875rem;">Please wait, you will be redirected automatically...</p>
                            <p style="color:#9ca3af; font-size:0.875rem; margin-top:10px;"><strong>Do not close this window or refresh the page.</strong></p>
                        </div>
                    </div>

                    <form method="POST" action="{{ route('sites.store') }}" id="site-create-form">
                        @csrf

                        <div class="mb-4">
                            <label for="site_name" class="block text-sm font-medium text-gray-700">Site Name</label>
                            <input type="text" name="site_name" id="site_name" required
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                   placeholder="mysite" value="{{ old('site_name') }}">
                            <p class="mt-1 text-sm text-gray-500">Only lowercase letters, numbers, and hyphens. Used for directory and database names.</p>
                        </div>

                        <div class="mb-4">
                            <label for="domain" class="block text-sm font-medium text-gray-700">Domain</label>
                            <input type="text" name="domain" id="domain" required
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                   placeholder="example.com" value="{{ old('domain') }}">
                            <p class="mt-1 text-sm text-gray-500">The domain name that will point to this site.</p>
                        </div>

                        <div class="mb-4">
                            <label for="php_version" class="block text-sm font-medium text-gray-700">PHP Version</label>
                            <select name="php_version" id="php_version" required
                                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <option value="8.3" {{ old('php_version') == '8.3' ? 'selected' : '' }}>PHP 8.3</option>
                                <option value="8.2" {{ old('php_version') == '8.2' ? 'selected' : '' }}>PHP 8.2</option>
                                <option value="8.1" {{ old('php_version') == '8.1' ? 'selected' : '' }}>PHP 8.1</option>
                            </select>
                        </div>

                        <div class="mb-4">
                            <label class="flex items-center">
                                <input type="checkbox" name="create_database" id="create_database" value="1" 
                                       {{ old('create_database', true) ? 'checked' : '' }}
                                       class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <span class="ml-2 text-sm text-gray-700">Create Database</span>
                            </label>
                            <p class="mt-1 text-sm text-gray-500">Automatically create a MySQL database for this site.</p>
                        </div>

                        <div class="mb-4">
                            <label class="flex items-center">
                                <input type="checkbox" name="installWP" id="installWP" value="1"
                                       {{ old('installWP') ? 'checked' : '' }}
                                       class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <span class="ml-2 text-sm text-gray-700">Install WordPress</span>
                            </label>
                            <p class="mt-1 text-sm text-gray-500">Download and install WordPress (requires database).</p>
                        </div>

                        <div class="mb-4">
                            <label class="flex items-center">
                                <input type="checkbox" name="enableCache" id="enableCache" value="1"
                                       {{ old('enableCache', true) ? 'checked' : '' }}
                                       class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <span class="ml-2 text-sm text-gray-700">Enable FastCGI Cache</span>
                            </label>
                            <p class="mt-1 text-sm text-gray-500">Enable NGINX FastCGI caching for better performance.</p>
                        </div>

                        <div class="flex items-center justify-between mt-6">
                            <a href="{{ route('sites.index') }}" class="text-gray-600 hover:text-gray-900">Cancel</a>
                            <button type="submit" id="submit-btn" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                                Create Site
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <div class="mt-6 bg-blue-50 border-l-4 border-blue-400 p-4">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <svg class="h-5 w-5 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>
                        </svg>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm text-blue-700">
                            After creating the site, you'll receive database credentials. Save them securely!
                            The site will be created at <code>/opt/webserver/sites/[sitename]/public_html</code>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // SPRINT57 v3.4: MINIMAL JAVASCRIPT - Only show overlay on submit
        console.log('SPRINT57 v3.4: FINAL SOLUTION - Traditional form submission');
        console.log('SPRINT57 v3.4: Script loaded');
        
        document.addEventListener('DOMContentLoaded', function() {
            console.log('SPRINT57 v3.4: DOM ready');
            
            const form = document.getElementById('site-create-form');
            const submitBtn = document.getElementById('submit-btn');
            const overlay = document.getElementById('processing-overlay');
            const progressBar = document.getElementById('progress-bar');
            
            if (!form) {
                console.error('SPRINT57 v3.4: Form not found');
                return;
            }
            
            console.log('SPRINT57 v3.4: Form found, attaching submit listener');
            
            // Only add overlay display on submit - don't prevent default
            form.addEventListener('submit', function(e) {
                console.log('SPRINT57 v3.4: Form submitting (traditional POST)');
                
                // Disable button to prevent double submit
                if (submitBtn) {
                    submitBtn.disabled = true;
                    submitBtn.textContent = 'Creating...';
                }
                
                // Show overlay
                if (overlay) {
                    overlay.style.display = 'flex';
                }
                
                // Start progress bar
                if (progressBar) {
                    let progress = 0;
                    const interval = setInterval(function() {
                        progress += 1;
                        progressBar.style.width = progress + '%';
                        if (progress >= 95) clearInterval(interval);
                    }, 300);
                }
                
                console.log('SPRINT57 v3.4: Overlay displayed, form will submit normally');
                // Let the form submit normally (no e.preventDefault())
            });
            
            console.log('SPRINT57 v3.4: Initialization complete');
        });
    </script>
</x-app-layout>
