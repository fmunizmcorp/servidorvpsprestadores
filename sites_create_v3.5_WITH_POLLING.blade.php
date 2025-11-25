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
                        <div class="mb-4 p-4 bg-green-100 border-l-4 border-green-500 text-green-700" id="success-message">
                            <p class="font-bold">Success!</p>
                            <p>{{ session('success') }}</p>
                            @if(session('creating_site_id'))
                                <p class="mt-2 text-sm">Checking status...</p>
                                <div id="status-indicator" class="mt-2">
                                    <div class="animate-pulse flex space-x-2">
                                        <div class="h-2 w-2 bg-green-600 rounded-full"></div>
                                        <div class="h-2 w-2 bg-green-600 rounded-full"></div>
                                        <div class="h-2 w-2 bg-green-600 rounded-full"></div>
                                    </div>
                                </div>
                            @endif
                        </div>
                    @endif

                    @if(session('error'))
                        <div class="mb-4 p-4 bg-red-100 border-l-4 border-red-500 text-red-700">
                            <p class="font-bold">Error!</p>
                            <p>{{ session('error') }}</p>
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
                            <h3 style="font-size:1.5rem; font-weight:bold; color:#1f2937; margin-bottom:10px;">Submitting Request...</h3>
                            <p style="color:#6b7280; margin-bottom:20px;">Site creation request is being submitted...</p>
                            <p style="color:#9ca3af; font-size:0.875rem;"><strong>Please wait...</strong></p>
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
                                <option value="8.3" {{ old('php_version', '8.3') == '8.3' ? 'selected' : '' }}>PHP 8.3</option>
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

                        <div class="flex items-center justify-between">
                            <button type="submit" id="submit-btn"
                                    class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline">
                                Create Site
                            </button>
                            <a href="{{ route('sites.index') }}" class="text-gray-600 hover:text-gray-900">Cancel</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script>
        console.log('SPRINT57 v3.5: Script loaded with polling support');

        document.addEventListener('DOMContentLoaded', function() {
            const form = document.getElementById('site-create-form');
            const overlay = document.getElementById('processing-overlay');
            const submitBtn = document.getElementById('submit-btn');
            
            console.log('SPRINT57 v3.5: DOM ready, form:', form ? 'found' : 'NOT FOUND');
            
            // Handle form submission - show overlay
            if (form) {
                form.addEventListener('submit', function(e) {
                    console.log('SPRINT57 v3.5: Form submitting (traditional POST with overlay)');
                    
                    // Disable button to prevent double submit
                    if (submitBtn) {
                        submitBtn.disabled = true;
                        submitBtn.textContent = 'Creating...';
                    }
                    
                    // Show overlay
                    if (overlay) {
                        overlay.style.display = 'flex';
                    }
                    
                    // Let the form submit naturally (NO e.preventDefault())
                    console.log('SPRINT57 v3.5: Form will submit naturally to server');
                });
            }
            
            // ============================================================
            // SPRINT57 v3.5: POLLING FOR SITE STATUS
            // ============================================================
            @if(session('creating_site_id'))
                const creatingSiteId = {{ session('creating_site_id') }};
                const creatingSiteName = '{{ session('creating_site_name') }}';
                
                console.log('SPRINT57 v3.5: Site is being created, starting polling', {
                    site_id: creatingSiteId,
                    site_name: creatingSiteName
                });
                
                let pollCount = 0;
                const maxPolls = 60; // Poll for up to 60 * 3 = 180 seconds (3 minutes)
                
                const pollInterval = setInterval(function() {
                    pollCount++;
                    
                    console.log('SPRINT57 v3.5: Polling attempt', pollCount, 'of', maxPolls);
                    
                    // Check site status via API
                    fetch('/api/sites/' + creatingSiteId + '/status')
                        .then(response => {
                            if (!response.ok) {
                                throw new Error('HTTP error ' + response.status);
                            }
                            return response.json();
                        })
                        .then(data => {
                            console.log('SPRINT57 v3.5: Status response:', data);
                            
                            if (data.status === 'active') {
                                console.log('SPRINT57 v3.5: Site is ACTIVE! Reloading page...');
                                
                                clearInterval(pollInterval);
                                
                                // Update success message
                                const successMsg = document.getElementById('success-message');
                                if (successMsg) {
                                    successMsg.innerHTML = '<p class="font-bold">Success!</p>' +
                                                          '<p>Site "' + creatingSiteName + '" has been created successfully!</p>' +
                                                          '<p class="mt-2 text-sm">Refreshing page...</p>';
                                }
                                
                                // Reload page to show updated site list
                                setTimeout(function() {
                                    window.location.reload();
                                }, 2000);
                                
                            } else if (data.status === 'failed') {
                                console.log('SPRINT57 v3.5: Site creation FAILED');
                                
                                clearInterval(pollInterval);
                                
                                // Show error message
                                const successMsg = document.getElementById('success-message');
                                if (successMsg) {
                                    successMsg.className = 'mb-4 p-4 bg-red-100 border-l-4 border-red-500 text-red-700';
                                    successMsg.innerHTML = '<p class="font-bold">Error!</p>' +
                                                          '<p>Site creation failed. Please check the logs.</p>';
                                }
                                
                            } else {
                                console.log('SPRINT57 v3.5: Site still creating, status:', data.status);
                                
                                // Update indicator
                                const indicator = document.getElementById('status-indicator');
                                if (indicator) {
                                    indicator.innerHTML = '<div class="animate-pulse flex space-x-2">' +
                                                         '<div class="h-2 w-2 bg-green-600 rounded-full"></div>' +
                                                         '<div class="h-2 w-2 bg-green-600 rounded-full"></div>' +
                                                         '<div class="h-2 w-2 bg-green-600 rounded-full"></div>' +
                                                         '</div>' +
                                                         '<p class="text-xs mt-1">Poll ' + pollCount + ' of ' + maxPolls + '</p>';
                                }
                            }
                        })
                        .catch(error => {
                            console.error('SPRINT57 v3.5: Polling error:', error);
                        });
                    
                    // Stop polling after max attempts
                    if (pollCount >= maxPolls) {
                        console.log('SPRINT57 v3.5: Max polling attempts reached, stopping');
                        clearInterval(pollInterval);
                        
                        const successMsg = document.getElementById('success-message');
                        if (successMsg) {
                            successMsg.innerHTML = '<p class="font-bold">Info</p>' +
                                                  '<p>Site creation is taking longer than expected. Please refresh the page to check status.</p>';
                        }
                    }
                    
                }, 3000); // Poll every 3 seconds
            @endif
        });
    </script>
</x-app-layout>
