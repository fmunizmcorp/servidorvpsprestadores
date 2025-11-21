<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Add Email Account') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 text-gray-900">
                    <form method="POST" action="{{ route('email.storeAccount') }}">
                        @csrf
                        
                        <div class="mb-4">
                            <label class="block text-gray-700 text-sm font-bold mb-2">Domain</label>
                            <select name="domain" class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700" required>
                                <option value="">Select a domain</option>
                                @foreach($domains as $domain)
                                    <option value="{{ $domain }}">{{ $domain }}</option>
                                @endforeach
                            </select>
                            <p class="text-gray-600 text-xs mt-1">Select the domain for this email account</p>
                        </div>
                        
                        <div class="mb-4">
                            <label class="block text-gray-700 text-sm font-bold mb-2">Username</label>
                            <input type="text" name="username" placeholder="username (without @domain)" class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700" required>
                            <p class="text-gray-600 text-xs mt-1">Enter username only, domain will be added automatically</p>
                        </div>
                        
                        <div class="mb-4">
                            <label class="block text-gray-700 text-sm font-bold mb-2">Password</label>
                            <input type="password" name="password" placeholder="Minimum 8 characters" class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700" required minlength="8">
                            <p class="text-gray-600 text-xs mt-1">Password must be at least 8 characters</p>
                        </div>
                        
                        <div class="mb-4">
                            <label class="block text-gray-700 text-sm font-bold mb-2">Quota (MB)</label>
                            <input type="number" name="quota" value="1024" min="100" max="10240" class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700" required>
                            <p class="text-gray-600 text-xs mt-1">Storage quota in megabytes (100 - 10240 MB)</p>
                        </div>
                        
                        <div class="flex items-center justify-between">
                            <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                                Create Account
                            </button>
                            <a href="{{ route('email.accounts') }}" class="text-gray-600 hover:text-gray-900">Cancel</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
