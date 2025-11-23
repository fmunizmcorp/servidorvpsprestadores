<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Email Accounts') }}
                @if(request('domain'))
                    <span class="text-sm text-gray-500">- {{ request('domain') }}</span>
                @endif
            </h2>
            <button onclick="document.getElementById('addAccountModal').classList.remove('hidden')" 
                    class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                Create Account
            </button>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))
                <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-4">
                    {{ session('success') }}
                </div>
            @endif

            @if (session('error'))
                <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4">
                    {{ session('error') }}
                </div>
            @endif

            @if (session('credentials'))
                <div class="bg-blue-100 border border-blue-400 text-blue-700 px-4 py-3 rounded relative mb-4">
                    <strong class="font-bold">Account Created Successfully!</strong>
                    <div class="mt-2">
                        <p><strong>Email:</strong> {{ session('credentials')['email'] }}</p>
                        <p><strong>Password:</strong> {{ session('credentials')['password'] }}</p>
                        <p class="text-sm mt-2">Save these credentials securely!</p>
                    </div>
                </div>
            @endif

            <!-- Domain Filter -->
            <div class="mb-6">
                <form method="GET" class="flex gap-4">
                    <select name="domain" class="rounded-md border-gray-300" onchange="this.form.submit()">
                        <option value="">All Domains</option>
                        @foreach ($domains as $d)
                            <option value="{{ $d }}" {{ request('domain') == $d ? 'selected' : '' }}>
                                {{ $d }}
                            </option>
                        @endforeach
                    </select>
                </form>
            </div>

            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Quota</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Used</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @php
                                $accountsWithId = collect($accounts)->map(function($account) {
                                    $acc = \App\Models\EmailAccount::where('email', $account['email'])->first();
                                    $account['id'] = $acc ? $acc->id : null;
                                    return $account;
                                });
                            @endphp
                            @forelse ($accountsWithId as $account)
                                <tr>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                                        {{ $account['email'] }}
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {{ $account['quota'] }}
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {{ $account['used'] }}
                                        <div class="w-full bg-gray-200 rounded-full h-2 mt-1">
                                            <div class="bg-blue-600 h-2 rounded-full" style="width: {{ $account['usagePercent'] }}%"></div>
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full 
                                            {{ $account['status'] == 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' }}">
                                            {{ ucfirst($account['status']) }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                        @if($account['id'])
                                            <a href="{{ route('email.accounts.edit', $account['id']) }}" 
                                               class="text-green-600 hover:text-green-900 mr-3">
                                                Edit
                                            </a>
                                        @endif
                                        <button onclick="showChangePassword('{{ $account['email'] }}')" 
                                                class="text-yellow-600 hover:text-yellow-900 mr-3">
                                            Password
                                        </button>
                                        <button onclick="showChangeQuota('{{ $account['email'] }}', '{{ str_replace(' MB', '', $account['quota']) }}')" 
                                                class="text-indigo-600 hover:text-indigo-900 mr-3">
                                            Quota
                                        </button>
                                        <form action="{{ route('email.deleteAccount') }}" method="POST" class="inline">
                                            @csrf
                                            @method('DELETE')
                                            <input type="hidden" name="email" value="{{ $account['email'] }}">
                                            <button type="submit" class="text-red-600 hover:text-red-900" 
                                                    onclick="return confirm('Delete {{ $account['email'] }}?')">
                                                Delete
                                            </button>
                                        </form>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500">
                                        No email accounts found.
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Webmail Access Info -->
            <div class="mt-6 bg-green-50 border-l-4 border-green-400 p-4">
                <div class="flex">
                    <div class="ml-3">
                        <h3 class="text-sm font-medium text-green-800">Webmail Access</h3>
                        <div class="mt-2 text-sm text-green-700">
                            <p><strong>Webmail URL:</strong> <a href="http://{{ request()->getHost() }}/webmail" target="_blank" class="underline">http://{{ request()->getHost() }}/webmail</a></p>
                            <p class="mt-1"><strong>IMAP:</strong> {{ request()->getHost() }}:993 (SSL/TLS)</p>
                            <p><strong>SMTP:</strong> {{ request()->getHost() }}:587 (STARTTLS) or :465 (SSL/TLS)</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Add Account Modal (keeping existing) -->
    <div id="addAccountModal" class="hidden fixed z-10 inset-0 overflow-y-auto">
        <div class="flex items-center justify-center min-h-screen px-4">
            <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
            <div class="bg-white rounded-lg overflow-hidden shadow-xl transform transition-all sm:max-w-lg sm:w-full z-20">
                <form method="POST" action="{{ route('email.storeAccount') }}">
                    @csrf
                    <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                        <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Create Email Account</h3>
                        
                        <div class="mb-4">
                            <label for="username" class="block text-sm font-medium text-gray-700">Username</label>
                            <input type="text" name="username" id="username" required
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
                                   placeholder="john.doe">
                        </div>

                        <div class="mb-4">
                            <label for="domain_select" class="block text-sm font-medium text-gray-700">Domain</label>
                            <select name="domain" id="domain_select" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm">
                                @foreach ($domains as $d)
                                    <option value="{{ $d }}" {{ request('domain') == $d ? 'selected' : '' }}>{{ $d }}</option>
                                @endforeach
                            </select>
                        </div>

                        <div class="mb-4">
                            <label for="password" class="block text-sm font-medium text-gray-700">Password</label>
                            <input type="password" name="password" id="password" required minlength="8"
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm">
                        </div>

                        <div class="mb-4">
                            <label for="quota" class="block text-sm font-medium text-gray-700">Quota (MB)</label>
                            <input type="number" name="quota" id="quota" required min="100" max="10240" value="1024"
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm">
                        </div>
                    </div>
                    <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                        <button type="submit" 
                                class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 sm:ml-3 sm:w-auto sm:text-sm">
                            Create Account
                        </button>
                        <button type="button" 
                                onclick="document.getElementById('addAccountModal').classList.add('hidden')"
                                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                            Cancel
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Change Password Modal -->
    <div id="changePasswordModal" class="hidden fixed z-10 inset-0 overflow-y-auto">
        <div class="flex items-center justify-center min-h-screen px-4">
            <div class="fixed inset-0 bg-gray-500 bg-opacity-75"></div>
            <div class="bg-white rounded-lg overflow-hidden shadow-xl transform transition-all sm:max-w-lg sm:w-full z-20">
                <form method="POST" action="{{ route('email.changePassword') }}">
                    @csrf
                    <input type="hidden" name="email" id="changePasswordEmail">
                    <div class="bg-white px-4 pt-5 pb-4 sm:p-6">
                        <h3 class="text-lg font-medium text-gray-900 mb-4">Change Password</h3>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700">New Password</label>
                            <input type="password" name="password" required minlength="8"
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm">
                        </div>
                    </div>
                    <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                        <button type="submit" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-yellow-600 text-white hover:bg-yellow-700 sm:ml-3 sm:w-auto sm:text-sm">
                            Update Password
                        </button>
                        <button type="button" onclick="document.getElementById('changePasswordModal').classList.add('hidden')"
                                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-gray-700 hover:bg-gray-50 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                            Cancel
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Change Quota Modal -->
    <div id="changeQuotaModal" class="hidden fixed z-10 inset-0 overflow-y-auto">
        <div class="flex items-center justify-center min-h-screen px-4">
            <div class="fixed inset-0 bg-gray-500 bg-opacity-75"></div>
            <div class="bg-white rounded-lg overflow-hidden shadow-xl transform transition-all sm:max-w-lg sm:w-full z-20">
                <form method="POST" action="{{ route('email.changeQuota') }}">
                    @csrf
                    <input type="hidden" name="email" id="changeQuotaEmail">
                    <div class="bg-white px-4 pt-5 pb-4 sm:p-6">
                        <h3 class="text-lg font-medium text-gray-900 mb-4">Change Quota</h3>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700">Quota (MB)</label>
                            <input type="number" name="quota" id="changeQuotaValue" required min="100" max="10240"
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm">
                        </div>
                    </div>
                    <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                        <button type="submit" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-white hover:bg-indigo-700 sm:ml-3 sm:w-auto sm:text-sm">
                            Update Quota
                        </button>
                        <button type="button" onclick="document.getElementById('changeQuotaModal').classList.add('hidden')"
                                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-gray-700 hover:bg-gray-50 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                            Cancel
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        function showChangePassword(email) {
            document.getElementById('changePasswordEmail').value = email;
            document.getElementById('changePasswordModal').classList.remove('hidden');
        }
        
        function showChangeQuota(email, currentQuota) {
            document.getElementById('changeQuotaEmail').value = email;
            document.getElementById('changeQuotaValue').value = currentQuota;
            document.getElementById('changeQuotaModal').classList.remove('hidden');
        }
    </script>
</x-app-layout>
