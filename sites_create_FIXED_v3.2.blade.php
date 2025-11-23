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
                                   placeholder="mysite">
                            <p class="mt-1 text-sm text-gray-500">Only lowercase letters, numbers, and hyphens. Used for directory and database names.</p>
                        </div>

                        <div class="mb-4">
                            <label for="domain" class="block text-sm font-medium text-gray-700">Domain</label>
                            <input type="text" name="domain" id="domain" required
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                   placeholder="example.com">
                            <p class="mt-1 text-sm text-gray-500">The domain name that will point to this site.</p>
                        </div>

                        <div class="mb-4">
                            <label for="php_version" class="block text-sm font-medium text-gray-700">PHP Version</label>
                            <select name="php_version" id="php_version" required
                                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <option value="8.3">PHP 8.3</option>
                                <option value="8.2">PHP 8.2</option>
                                <option value="8.1">PHP 8.1</option>
                            </select>
                        </div>

                        <div class="mb-4">
                            <label class="flex items-center">
                                <input type="checkbox" name="create_database" id="create_database" value="1" checked
                                       class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <span class="ml-2 text-sm text-gray-700">Create Database</span>
                            </label>
                            <p class="mt-1 text-sm text-gray-500">Automatically create a MySQL database for this site.</p>
                        </div>

                        <div class="mb-4">
                            <label class="flex items-center">
                                <input type="checkbox" name="installWP" id="installWP"
                                       class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <span class="ml-2 text-sm text-gray-700">Install WordPress</span>
                            </label>
                            <p class="mt-1 text-sm text-gray-500">Download and install WordPress (requires database).</p>
                        </div>

                        <div class="mb-4">
                            <label class="flex items-center">
                                <input type="checkbox" name="enableCache" id="enableCache" checked
                                       class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <span class="ml-2 text-sm text-gray-700">Enable FastCGI Cache</span>
                            </label>
                            <p class="mt-1 text-sm text-gray-500">Enable NGINX FastCGI caching for better performance.</p>
                        </div>

                        <div class="flex items-center justify-between mt-6">
                            <a href="{{ route('sites.index') }}" class="text-gray-600 hover:text-gray-900">Cancel</a>
                            <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
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
        // SPRINT57 v3.2: CSRF token refresh with Fetch API submission (NO RECURSION)
        console.log('SPRINT57 v3.2: Script loaded');
        
        document.addEventListener('DOMContentLoaded', function() {
            console.log('SPRINT57 v3.2: DOM ready, attaching event listener');
            
            const form = document.getElementById('site-create-form');
            if (!form) {
                console.error('SPRINT57 v3.2: Form not found!');
                return;
            }
            
            console.log('SPRINT57 v3.2: Form found, ID:', form.id);
            
            form.addEventListener('submit', function(e) {
                console.log('SPRINT57 v3.2: Form submit intercepted!');
                e.preventDefault();
                console.log('SPRINT57 v3.2: Default submission prevented');
                
                const submitBtn = form.querySelector('button[type="submit"]');
                const overlay = document.getElementById('processing-overlay');
                const progressBar = document.getElementById('progress-bar');
                
                console.log('SPRINT57 v3.2: Fetching fresh CSRF token...');
                
                fetch('/csrf-refresh', {
                    method: 'GET',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Accept': 'application/json'
                    },
                    credentials: 'same-origin'
                })
                .then(response => {
                    console.log('SPRINT57 v3.2: CSRF refresh response status:', response.status);
                    if (!response.ok) {
                        throw new Error('Failed to fetch CSRF token: ' + response.status);
                    }
                    return response.json();
                })
                .then(data => {
                    console.log('SPRINT57 v3.2: Received fresh CSRF token:', data.token.substring(0, 10) + '...');
                    
                    // Show overlay BEFORE submission
                    overlay.style.display = 'flex';
                    submitBtn.disabled = true;
                    submitBtn.style.opacity = '0.5';
                    submitBtn.textContent = 'Creating...';
                    console.log('SPRINT57 v3.2: Processing overlay displayed');
                    
                    // Start progress bar animation
                    let progress = 0;
                    const interval = setInterval(function() {
                        progress += 1;
                        progressBar.style.width = progress + '%';
                        if (progress >= 95) clearInterval(interval);
                    }, 300);
                    console.log('SPRINT57 v3.2: Progress bar animation started');
                    
                    // CRITICAL FIX: Use Fetch API with FormData to submit WITHOUT triggering event listener again
                    console.log('SPRINT57 v3.2: Creating FormData from form');
                    const formData = new FormData(form);
                    
                    // Update CSRF token in FormData (NOT in form, to avoid any issues)
                    formData.set('_token', data.token);
                    console.log('SPRINT57 v3.2: CSRF token updated in FormData');
                    
                    // Get form action URL
                    const actionUrl = form.action;
                    console.log('SPRINT57 v3.2: Form action URL:', actionUrl);
                    
                    // Submit form data via Fetch API (NO EVENT LISTENER TRIGGERED)
                    console.log('SPRINT57 v3.2: Submitting form via Fetch API...');
                    
                    return fetch(actionUrl, {
                        method: 'POST',
                        body: formData,
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest',
                            'Accept': 'application/json'
                        },
                        credentials: 'same-origin'
                    });
                })
                .then(response => {
                    console.log('SPRINT57 v3.2: Site creation response status:', response.status);
                    
                    if (response.status === 422) {
                        // Validation errors
                        return response.json().then(data => {
                            throw new Error('Validation failed: ' + JSON.stringify(data.errors || data.message));
                        });
                    }
                    
                    if (!response.ok) {
                        throw new Error('Site creation failed with status: ' + response.status);
                    }
                    
                    return response.json();
                })
                .then(data => {
                    console.log('SPRINT57 v3.2: Site created successfully!', data);
                    
                    // Complete progress bar
                    progressBar.style.width = '100%';
                    
                    // Redirect to sites list or show success message
                    if (data.redirect) {
                        console.log('SPRINT57 v3.2: Redirecting to:', data.redirect);
                        window.location.href = data.redirect;
                    } else {
                        console.log('SPRINT57 v3.2: Redirecting to sites index');
                        window.location.href = '{{ route("sites.index") }}';
                    }
                })
                .catch(error => {
                    console.error('SPRINT57 v3.2: Error during site creation:', error);
                    
                    // Hide overlay and re-enable button
                    overlay.style.display = 'none';
                    submitBtn.disabled = false;
                    submitBtn.style.opacity = '1';
                    submitBtn.textContent = 'Create Site';
                    
                    alert('Failed to create site. Please try again.\n\nError: ' + error.message);
                });
            });
            
            console.log('SPRINT57 v3.2: Event listener attached successfully');
        });
    </script>
</x-app-layout>
