<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">Edit Site: {{ $site['name'] }}</h2></x-slot>
    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))<div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">{{ session('success') }}</div>@endif
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <form method="POST" action="{{ route('sites.update', $site['name']) }}">
                        @csrf @method('PUT')
                        <div class="mb-4"><label class="block text-sm font-medium text-gray-700">Domain</label><input type="text" name="domain" value="{{ $site['domain'] }}" class="mt-1 block w-full rounded-md border-gray-300" required></div>
                        <div class="mb-4"><label class="block text-sm font-medium text-gray-700">PHP Version</label><select name="phpVersion" class="mt-1 block w-full rounded-md border-gray-300"><option value="8.3" {{ $site['phpVersion'] == '8.3' ? 'selected' : '' }}>PHP 8.3</option><option value="8.2" {{ $site['phpVersion'] == '8.2' ? 'selected' : '' }}>PHP 8.2</option><option value="8.1" {{ $site['phpVersion'] == '8.1' ? 'selected' : '' }}>PHP 8.1</option></select></div>
                        <div class="mb-4"><label class="flex items-center"><input type="checkbox" name="enableCache" {{ $site['cache'] ? 'checked' : '' }} class="rounded border-gray-300"><span class="ml-2 text-sm">Enable FastCGI Cache</span></label></div>
                        <div class="flex items-center justify-between mt-6"><a href="{{ route('sites.show', $site['name']) }}" class="text-gray-600 hover:text-gray-900">Cancel</a><button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Update Site</button></div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
