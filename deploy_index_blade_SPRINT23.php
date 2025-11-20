<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Sprint 23 - Deployment Console') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 text-gray-900">
                    <div class="mb-6">
                        <h3 class="text-lg font-semibold mb-4">🚨 Emergency Deployment - Sprint 23</h3>
                        <p class="text-sm text-gray-600 mb-4">
                            This page allows you to deploy the Sprint 22/23 fixes without SSH access.
                            The deployment will automatically apply sudo fixes to EmailController.php and configure permissions.
                        </p>
                    </div>

                    <!-- Deployment Status -->
                    <div id="status-section" class="mb-6 p-4 bg-gray-100 rounded-lg">
                        <h4 class="font-semibold mb-2">Current Status</h4>
                        <div id="status-content">
                            <p class="text-sm text-gray-500">Loading status...</p>
                        </div>
                    </div>

                    <!-- Execute Button -->
                    <div class="mb-6">
                        <button 
                            id="execute-deploy"
                            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
                            onclick="executeDeploy()">
                            🚀 Execute Deployment Now
                        </button>
                    </div>

                    <!-- Results Section -->
                    <div id="results-section" class="hidden">
                        <h4 class="font-semibold mb-2">Deployment Results</h4>
                        <div id="results-content" class="p-4 bg-white border rounded-lg">
                        </div>
                    </div>

                    <!-- Instructions -->
                    <div class="mt-8 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                        <h4 class="font-semibold mb-2">📋 Instructions</h4>
                        <ol class="list-decimal ml-5 text-sm space-y-1">
                            <li>Check current status above</li>
                            <li>Click "Execute Deployment Now" button</li>
                            <li>Wait for deployment to complete (may take 30-60 seconds)</li>
                            <li>Review results and verify all steps succeeded</li>
                            <li>Test the 3 forms: Email Domain, Email Account, Site Creation</li>
                        </ol>
                    </div>

                    <!-- Testing Links -->
                    <div class="mt-6 p-4 bg-green-50 border border-green-200 rounded-lg">
                        <h4 class="font-semibold mb-2">✅ Testing Links (After Deployment)</h4>
                        <ul class="list-disc ml-5 text-sm space-y-1">
                            <li><a href="{{ route('email.domains') }}" class="text-blue-600 hover:underline">Email Domains</a> - Test creating a domain</li>
                            <li><a href="{{ route('email.accounts') }}" class="text-blue-600 hover:underline">Email Accounts</a> - Test creating an account</li>
                            <li><a href="{{ route('sites.create') }}" class="text-blue-600 hover:underline">Site Creation</a> - Test creating a site</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Load status on page load
        document.addEventListener('DOMContentLoaded', function() {
            loadStatus();
        });

        function loadStatus() {
            fetch('/admin/deploy/status')
                .then(response => response.json())
                .then(data => {
                    displayStatus(data);
                })
                .catch(error => {
                    document.getElementById('status-content').innerHTML = 
                        '<p class="text-red-600">Error loading status: ' + error.message + '</p>';
                });
        }

        function displayStatus(data) {
            let html = '<div class="space-y-2">';
            
            html += '<div class="flex items-center space-x-2">';
            html += '<span class="' + (data.emailcontroller_fixed ? 'text-green-600' : 'text-red-600') + '">';
            html += data.emailcontroller_fixed ? '✅' : '❌';
            html += '</span>';
            html += '<span class="text-sm">EmailController.php has sudo fixes</span>';
            html += '</div>';
            
            html += '<div class="flex items-center space-x-2">';
            html += '<span class="' + (data.sudoers_configured ? 'text-green-600' : 'text-red-600') + '">';
            html += data.sudoers_configured ? '✅' : '❌';
            html += '</span>';
            html += '<span class="text-sm">Sudo permissions configured</span>';
            html += '</div>';
            
            html += '<div class="flex items-center space-x-2">';
            html += '<span class="' + (data.scripts_exist ? 'text-green-600' : 'text-red-600') + '">';
            html += data.scripts_exist ? '✅' : '❌';
            html += '</span>';
            html += '<span class="text-sm">Shell scripts exist</span>';
            html += '</div>';
            
            html += '<div class="mt-4 p-2 rounded ' + 
                (data.overall_status === 'ready' ? 'bg-green-100' : 'bg-yellow-100') + '">';
            html += '<strong>Overall Status:</strong> ' + data.overall_status.toUpperCase();
            html += '</div>';
            
            if (data.recommendations && data.recommendations.length > 0) {
                html += '<div class="mt-4">';
                html += '<strong class="text-sm">Recommendations:</strong>';
                html += '<ul class="list-disc ml-5 text-sm">';
                data.recommendations.forEach(rec => {
                    html += '<li>' + rec + '</li>';
                });
                html += '</ul>';
                html += '</div>';
            }
            
            html += '</div>';
            
            document.getElementById('status-content').innerHTML = html;
        }

        function executeDeploy() {
            const button = document.getElementById('execute-deploy');
            button.disabled = true;
            button.textContent = '⏳ Deploying...';
            
            document.getElementById('results-section').classList.remove('hidden');
            document.getElementById('results-content').innerHTML = 
                '<p class="text-sm text-gray-500">Executing deployment... Please wait...</p>';
            
            fetch('/admin/deploy/execute?secret=sprint23deploy')
                .then(response => response.json())
                .then(data => {
                    displayResults(data);
                    button.disabled = false;
                    button.textContent = '🚀 Execute Deployment Now';
                    // Reload status
                    loadStatus();
                })
                .catch(error => {
                    document.getElementById('results-content').innerHTML = 
                        '<p class="text-red-600">Deployment failed: ' + error.message + '</p>';
                    button.disabled = false;
                    button.textContent = '🚀 Execute Deployment Now';
                });
        }

        function displayResults(data) {
            let html = '<div class="space-y-4">';
            
            // Overall status
            html += '<div class="p-3 rounded ' + 
                (data.success ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800') + '">';
            html += '<strong>' + (data.success ? '✅ SUCCESS' : '❌ FAILED') + ':</strong> ';
            html += data.message;
            html += '</div>';
            
            // Steps
            if (data.steps && data.steps.length > 0) {
                html += '<div class="border rounded p-3">';
                html += '<strong class="text-sm">Deployment Steps:</strong>';
                html += '<div class="mt-2 space-y-2">';
                data.steps.forEach(step => {
                    html += '<div class="text-sm p-2 bg-gray-50 rounded">';
                    html += '<div class="font-semibold">' + step.step.toUpperCase() + '</div>';
                    html += '<div class="text-gray-600">' + step.message + '</div>';
                    if (step.status === 'warning') {
                        html += '<div class="text-yellow-600 mt-1">⚠️ Warning: Check manually</div>';
                    }
                    html += '</div>';
                });
                html += '</div>';
                html += '</div>';
            }
            
            // Errors
            if (data.errors && data.errors.length > 0) {
                html += '<div class="p-3 bg-red-50 border border-red-200 rounded">';
                html += '<strong class="text-red-800">Errors:</strong>';
                html += '<ul class="list-disc ml-5 text-sm text-red-700">';
                data.errors.forEach(error => {
                    html += '<li>' + error + '</li>';
                });
                html += '</ul>';
                html += '</div>';
            }
            
            // Next steps
            html += '<div class="p-3 bg-blue-50 border border-blue-200 rounded">';
            html += '<strong class="text-blue-800">Next Steps:</strong>';
            html += '<ol class="list-decimal ml-5 text-sm text-blue-700 space-y-1">';
            html += '<li>Test Email Domain creation</li>';
            html += '<li>Test Email Account creation</li>';
            html += '<li>Test Site creation</li>';
            html += '<li>Verify data persistence in /etc/postfix/ and /opt/webserver/sites/</li>';
            html += '</ol>';
            html += '</div>';
            
            html += '</div>';
            
            document.getElementById('results-content').innerHTML = html;
        }
    </script>
</x-app-layout>
