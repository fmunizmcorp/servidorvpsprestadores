<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Edit Email Account') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @if (session('error'))
                <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4">
                    {{ session('error') }}
                </div>
            @endif

            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 text-gray-900">
                    <form method="POST" action="{{ route('email.accounts.update', $account->id) }}">
                        @csrf
                        @method('PUT')
                        
                        <div class="mb-4">
                            <label class="block text-gray-700 text-sm font-bold mb-2">Username</label>
                            <input type="text" name="username" value="{{ old('username', $account->username) }}" 
                                   placeholder="john.doe" 
                                   class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700" 
                                   required>
                            @error('username')
                                <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                            @enderror
                        </div>
                        
                        <div class="mb-4">
                            <label class="block text-gray-700 text-sm font-bold mb-2">Domain</label>
                            <select name="domain" class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700" required>
                                @foreach($domains as $d)
                                    <option value="{{ $d }}" {{ old('domain', $account->domain) == $d ? 'selected' : '' }}>
                                        {{ $d }}
                                    </option>
                                @endforeach
                            </select>
                            @error('domain')
                                <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                            @enderror
                        </div>
                        
                        <div class="mb-4">
                            <label class="block text-gray-700 text-sm font-bold mb-2">Quota (MB)</label>
                            <input type="number" name="quota" value="{{ old('quota', $account->quota) }}" 
                                   min="100" max="10240"
                                   class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700" 
                                   required>
                            <p class="text-gray-600 text-xs mt-1">Minimum: 100 MB, Maximum: 10240 MB</p>
                            @error('quota')
                                <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                            @enderror
                        </div>
                        
                        <div class="mb-4">
                            <label class="block text-gray-700 text-sm font-bold mb-2">Status</label>
                            <select name="status" class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700" required>
                                <option value="active" {{ old('status', $account->status) == 'active' ? 'selected' : '' }}>Active</option>
                                <option value="inactive" {{ old('status', $account->status) == 'inactive' ? 'selected' : '' }}>Inactive</option>
                            </select>
                            @error('status')
                                <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                            @enderror
                        </div>
                        
                        <div class="mb-4">
                            <label class="block text-gray-700 text-sm font-bold mb-2">New Password (Optional)</label>
                            <input type="password" name="password" 
                                   placeholder="Leave empty to keep current password"
                                   class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700">
                            <p class="text-gray-600 text-xs mt-1">Only fill this if you want to change the password</p>
                            @error('password')
                                <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                            @enderror
                        </div>
                        
                        <div class="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-4">
                            <div class="flex">
                                <div class="flex-shrink-0">
                                    <svg class="h-5 w-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
                                    </svg>
                                </div>
                                <div class="ml-3">
                                    <p class="text-sm text-yellow-700">
                                        <strong>Warning:</strong> Changing the email address will rename the mailbox on the system. 
                                        This is a critical operation. Ensure the new email is correct.
                                    </p>
                                </div>
                            </div>
                        </div>
                        
                        <div class="flex items-center justify-between">
                            <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                                Update Account
                            </button>
                            <a href="{{ route('email.accounts', ['domain' => $account->domain]) }}" class="text-gray-600 hover:text-gray-900">Cancel</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
