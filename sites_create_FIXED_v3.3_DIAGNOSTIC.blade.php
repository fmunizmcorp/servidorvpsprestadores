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

                    <form method="POST" id="site-create-form" novalidate>
                        @csrf

                        <div class="mb-4">
                            <label for="site_name" class="block text-sm font-medium text-gray-700">Site Name</label>
                            <input type="text" name="site_name" id="site_name"
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                   placeholder="mysite">
                            <p class="mt-1 text-sm text-gray-500">Only lowercase letters, numbers, and hyphens. Used for directory and database names.</p>
                        </div>

                        <div class="mb-4">
                            <label for="domain" class="block text-sm font-medium text-gray-700">Domain</label>
                            <input type="text" name="domain" id="domain"
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                   placeholder="example.com">
                            <p class="mt-1 text-sm text-gray-500">The domain name that will point to this site.</p>
                        </div>

                        <div class="mb-4">
                            <label for="php_version" class="block text-sm font-medium text-gray-700">PHP Version</label>
                            <select name="php_version" id="php_version"
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
                            <button type="button" id="submit-button" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
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
        // SPRINT57 v3.3: COMPREHENSIVE DIAGNOSTIC VERSION
        console.log('SPRINT57 v3.3: ========================================');
        console.log('SPRINT57 v3.3: DIAGNOSTIC VERSION LOADED');
        console.log('SPRINT57 v3.3: Script execution started');
        console.log('SPRINT57 v3.3: ========================================');
        
        // Log immediately - don't wait for DOMContentLoaded
        console.log('SPRINT57 v3.3: [IMMEDIATE] Script is executing');
        console.log('SPRINT57 v3.3: [IMMEDIATE] Current timestamp:', new Date().toISOString());
        console.log('SPRINT57 v3.3: [IMMEDIATE] Document readyState:', document.readyState);
        
        // Function to handle form submission - defined BEFORE DOMContentLoaded
        function handleFormSubmission(event) {
            console.log('SPRINT57 v3.3: ========================================');
            console.log('SPRINT57 v3.3: [CRITICAL] handleFormSubmission CALLED!');
            console.log('SPRINT57 v3.3: [CRITICAL] Event type:', event ? event.type : 'NO EVENT');
            console.log('SPRINT57 v3.3: [CRITICAL] Event target:', event ? event.target : 'NO TARGET');
            console.log('SPRINT57 v3.3: [CRITICAL] Timestamp:', new Date().toISOString());
            console.log('SPRINT57 v3.3: ========================================');
            
            if (event) {
                event.preventDefault();
                event.stopPropagation();
                console.log('SPRINT57 v3.3: [CRITICAL] Event prevented and stopped');
            }
            
            const form = document.getElementById('site-create-form');
            console.log('SPRINT57 v3.3: Form element:', form);
            
            if (!form) {
                console.error('SPRINT57 v3.3: [ERROR] Form not found!');
                return;
            }
            
            // Validate form fields manually
            const siteName = form.querySelector('[name="site_name"]').value;
            const domain = form.querySelector('[name="domain"]').value;
            
            console.log('SPRINT57 v3.3: Site name:', siteName);
            console.log('SPRINT57 v3.3: Domain:', domain);
            
            if (!siteName || !domain) {
                console.error('SPRINT57 v3.3: [ERROR] Missing required fields!');
                alert('Please fill in Site Name and Domain');
                return;
            }
            
            const submitBtn = document.getElementById('submit-button');
            const overlay = document.getElementById('processing-overlay');
            const progressBar = document.getElementById('progress-bar');
            
            console.log('SPRINT57 v3.3: Submit button:', submitBtn);
            console.log('SPRINT57 v3.3: Overlay:', overlay);
            console.log('SPRINT57 v3.3: Progress bar:', progressBar);
            
            // Disable button and show overlay
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.textContent = 'Creating...';
                console.log('SPRINT57 v3.3: Button disabled');
            }
            
            if (overlay) {
                overlay.style.display = 'flex';
                console.log('SPRINT57 v3.3: Overlay displayed');
            }
            
            // Start progress bar
            let progress = 0;
            const interval = setInterval(function() {
                progress += 1;
                if (progressBar) {
                    progressBar.style.width = progress + '%';
                }
                if (progress >= 95) clearInterval(interval);
            }, 300);
            console.log('SPRINT57 v3.3: Progress bar started');
            
            // Step 1: Refresh CSRF token
            console.log('SPRINT57 v3.3: [STEP 1] Fetching fresh CSRF token...');
            console.log('SPRINT57 v3.3: [STEP 1] URL: /csrf-refresh');
            
            fetch('/csrf-refresh', {
                method: 'GET',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                    'Accept': 'application/json'
                },
                credentials: 'same-origin'
            })
            .then(response => {
                console.log('SPRINT57 v3.3: [STEP 2] CSRF response received');
                console.log('SPRINT57 v3.3: [STEP 2] Status:', response.status);
                console.log('SPRINT57 v3.3: [STEP 2] OK:', response.ok);
                
                if (!response.ok) {
                    throw new Error('CSRF refresh failed: ' + response.status);
                }
                return response.json();
            })
            .then(data => {
                console.log('SPRINT57 v3.3: [STEP 3] CSRF data parsed');
                console.log('SPRINT57 v3.3: [STEP 3] Token:', data.token ? data.token.substring(0, 20) + '...' : 'NO TOKEN');
                
                // Step 2: Create FormData
                console.log('SPRINT57 v3.3: [STEP 4] Creating FormData...');
                const formData = new FormData(form);
                
                // Update CSRF token
                formData.set('_token', data.token);
                console.log('SPRINT57 v3.3: [STEP 4] CSRF token updated in FormData');
                
                // Log all form data
                console.log('SPRINT57 v3.3: [STEP 4] FormData contents:');
                for (let [key, value] of formData.entries()) {
                    if (key === '_token') {
                        console.log('SPRINT57 v3.3: [STEP 4]   ' + key + ':', value.substring(0, 20) + '...');
                    } else {
                        console.log('SPRINT57 v3.3: [STEP 4]   ' + key + ':', value);
                    }
                }
                
                // Step 3: Submit via Fetch API
                const actionUrl = '{{ route("sites.store") }}';
                console.log('SPRINT57 v3.3: [STEP 5] Submitting to:', actionUrl);
                console.log('SPRINT57 v3.3: [STEP 5] Method: POST');
                console.log('SPRINT57 v3.3: [STEP 5] Using Fetch API...');
                
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
                console.log('SPRINT57 v3.3: [STEP 6] Site creation response received');
                console.log('SPRINT57 v3.3: [STEP 6] Status:', response.status);
                console.log('SPRINT57 v3.3: [STEP 6] OK:', response.ok);
                console.log('SPRINT57 v3.3: [STEP 6] Status text:', response.statusText);
                
                if (response.status === 422) {
                    return response.json().then(data => {
                        console.error('SPRINT57 v3.3: [ERROR] Validation failed:', data);
                        throw new Error('Validation failed: ' + JSON.stringify(data.errors || data.message));
                    });
                }
                
                if (!response.ok) {
                    throw new Error('Site creation failed: ' + response.status + ' ' + response.statusText);
                }
                
                return response.json();
            })
            .then(data => {
                console.log('SPRINT57 v3.3: [STEP 7] Site creation successful!');
                console.log('SPRINT57 v3.3: [STEP 7] Response data:', data);
                
                // Complete progress bar
                if (progressBar) {
                    progressBar.style.width = '100%';
                }
                
                // Redirect
                const redirectUrl = data.redirect || '{{ route("sites.index") }}';
                console.log('SPRINT57 v3.3: [STEP 8] Redirecting to:', redirectUrl);
                
                setTimeout(function() {
                    window.location.href = redirectUrl;
                }, 500);
            })
            .catch(error => {
                console.error('SPRINT57 v3.3: ========================================');
                console.error('SPRINT57 v3.3: [ERROR] Site creation failed!');
                console.error('SPRINT57 v3.3: [ERROR] Error:', error);
                console.error('SPRINT57 v3.3: [ERROR] Error message:', error.message);
                console.error('SPRINT57 v3.3: [ERROR] Error stack:', error.stack);
                console.error('SPRINT57 v3.3: ========================================');
                
                // Hide overlay and re-enable button
                if (overlay) {
                    overlay.style.display = 'none';
                }
                if (submitBtn) {
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Create Site';
                }
                
                alert('Failed to create site.\n\nError: ' + error.message + '\n\nPlease check the console for details.');
            });
        }
        
        // Wait for DOM to be ready
        if (document.readyState === 'loading') {
            console.log('SPRINT57 v3.3: Document still loading, waiting for DOMContentLoaded...');
            document.addEventListener('DOMContentLoaded', function() {
                console.log('SPRINT57 v3.3: [DOM] DOMContentLoaded event fired');
                initializeForm();
            });
        } else {
            console.log('SPRINT57 v3.3: Document already loaded, initializing immediately');
            initializeForm();
        }
        
        function initializeForm() {
            console.log('SPRINT57 v3.3: ========================================');
            console.log('SPRINT57 v3.3: [INIT] Initializing form...');
            console.log('SPRINT57 v3.3: [INIT] Timestamp:', new Date().toISOString());
            console.log('SPRINT57 v3.3: ========================================');
            
            const form = document.getElementById('site-create-form');
            const submitButton = document.getElementById('submit-button');
            
            console.log('SPRINT57 v3.3: [INIT] Form element:', form);
            console.log('SPRINT57 v3.3: [INIT] Submit button:', submitButton);
            
            if (!form) {
                console.error('SPRINT57 v3.3: [INIT ERROR] Form not found!');
                return;
            }
            
            if (!submitButton) {
                console.error('SPRINT57 v3.3: [INIT ERROR] Submit button not found!');
                return;
            }
            
            console.log('SPRINT57 v3.3: [INIT] Form ID:', form.id);
            console.log('SPRINT57 v3.3: [INIT] Form method:', form.method);
            console.log('SPRINT57 v3.3: [INIT] Form novalidate:', form.noValidate);
            console.log('SPRINT57 v3.3: [INIT] Button ID:', submitButton.id);
            console.log('SPRINT57 v3.3: [INIT] Button type:', submitButton.type);
            
            // Attach click event to button (PRIMARY METHOD)
            console.log('SPRINT57 v3.3: [INIT] Attaching click event to button...');
            submitButton.addEventListener('click', function(e) {
                console.log('SPRINT57 v3.3: ========================================');
                console.log('SPRINT57 v3.3: [CLICK] Button clicked!');
                console.log('SPRINT57 v3.3: [CLICK] Event:', e);
                console.log('SPRINT57 v3.3: [CLICK] Target:', e.target);
                console.log('SPRINT57 v3.3: [CLICK] Timestamp:', new Date().toISOString());
                console.log('SPRINT57 v3.3: ========================================');
                
                e.preventDefault();
                e.stopPropagation();
                
                handleFormSubmission(e);
            });
            console.log('SPRINT57 v3.3: [INIT] Click event attached to button');
            
            // ALSO attach submit event to form (BACKUP METHOD)
            console.log('SPRINT57 v3.3: [INIT] Attaching submit event to form...');
            form.addEventListener('submit', function(e) {
                console.log('SPRINT57 v3.3: ========================================');
                console.log('SPRINT57 v3.3: [SUBMIT] Form submit event!');
                console.log('SPRINT57 v3.3: [SUBMIT] Event:', e);
                console.log('SPRINT57 v3.3: [SUBMIT] Target:', e.target);
                console.log('SPRINT57 v3.3: [SUBMIT] Timestamp:', new Date().toISOString());
                console.log('SPRINT57 v3.3: ========================================');
                
                e.preventDefault();
                e.stopPropagation();
                
                handleFormSubmission(e);
            });
            console.log('SPRINT57 v3.3: [INIT] Submit event attached to form');
            
            console.log('SPRINT57 v3.3: ========================================');
            console.log('SPRINT57 v3.3: [INIT] Initialization complete!');
            console.log('SPRINT57 v3.3: [INIT] Click button to test');
            console.log('SPRINT57 v3.3: ========================================');
        }
        
        // Global error handler
        window.addEventListener('error', function(e) {
            console.error('SPRINT57 v3.3: [GLOBAL ERROR]', e);
        });
        
        // Log when script finishes loading
        console.log('SPRINT57 v3.3: ========================================');
        console.log('SPRINT57 v3.3: Script loaded completely');
        console.log('SPRINT57 v3.3: Waiting for DOM or initializing...');
        console.log('SPRINT57 v3.3: ========================================');
    </script>
</x-app-layout>
