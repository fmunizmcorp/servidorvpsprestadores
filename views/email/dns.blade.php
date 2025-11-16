<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('DNS Verification') }}
            @if(request('domain'))
                <span class="text-sm text-gray-500">- {{ request('domain') }}</span>
            @endif
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <!-- Domain Selector -->
            <div class="mb-6">
                <form method="GET" class="flex gap-4">
                    <select name="domain" class="rounded-md border-gray-300" onchange="this.form.submit()">
                        <option value="">Select Domain</option>
                        @foreach ($domains as $d)
                            <option value="{{ $d }}" {{ request('domain') == $d ? 'selected' : '' }}>
                                {{ $d }}
                            </option>
                        @endforeach
                    </select>
                    <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                        Check DNS
                    </button>
                </form>
            </div>

            @if(request('domain') && isset($dnsRecords))
                <!-- Overall Status -->
                <div class="mb-6">
                    @if ($dnsRecords['allValid'])
                        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded">
                            <div class="flex items-center">
                                <svg class="h-5 w-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                                </svg>
                                <span class="font-semibold">All DNS records are properly configured!</span>
                            </div>
                        </div>
                    @else
                        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
                            <div class="flex items-center">
                                <svg class="h-5 w-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                                </svg>
                                <span class="font-semibold">Some DNS records need attention</span>
                            </div>
                        </div>
                    @endif
                </div>

                <!-- DNS Records -->
                <div class="space-y-4">
                    <!-- MX Record -->
                    <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                        <div class="p-6">
                            <div class="flex justify-between items-start">
                                <div class="flex-1">
                                    <h3 class="text-lg font-semibold mb-2 flex items-center">
                                        MX (Mail Exchange) Record
                                        @if ($dnsRecords['mx']['status'] == 'pass')
                                            <svg class="h-5 w-5 text-green-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                                            </svg>
                                        @else
                                            <svg class="h-5 w-5 text-red-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                                            </svg>
                                        @endif
                                    </h3>
                                    <p class="text-sm text-gray-600 mb-2">{{ $dnsRecords['mx']['description'] }}</p>
                                    @if (!empty($dnsRecords['mx']['value']))
                                        <div class="bg-gray-50 p-3 rounded font-mono text-sm">
                                            {{ $dnsRecords['mx']['value'] }}
                                        </div>
                                    @endif
                                    @if (!empty($dnsRecords['mx']['expected']))
                                        <p class="text-sm text-gray-500 mt-2"><strong>Expected:</strong> {{ $dnsRecords['mx']['expected'] }}</p>
                                    @endif
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- A Record -->
                    <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                        <div class="p-6">
                            <h3 class="text-lg font-semibold mb-2 flex items-center">
                                A (Address) Record
                                @if ($dnsRecords['a']['status'] == 'pass')
                                    <svg class="h-5 w-5 text-green-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                                    </svg>
                                @else
                                    <svg class="h-5 w-5 text-red-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                                    </svg>
                                @endif
                            </h3>
                            <p class="text-sm text-gray-600 mb-2">{{ $dnsRecords['a']['description'] }}</p>
                            @if (!empty($dnsRecords['a']['value']))
                                <div class="bg-gray-50 p-3 rounded font-mono text-sm">
                                    {{ $dnsRecords['a']['value'] }}
                                </div>
                            @endif
                        </div>
                    </div>

                    <!-- SPF Record -->
                    <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                        <div class="p-6">
                            <h3 class="text-lg font-semibold mb-2 flex items-center">
                                SPF (Sender Policy Framework)
                                @if ($dnsRecords['spf']['status'] == 'pass')
                                    <svg class="h-5 w-5 text-green-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                                    </svg>
                                @else
                                    <svg class="h-5 w-5 text-red-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                                    </svg>
                                @endif
                            </h3>
                            <p class="text-sm text-gray-600 mb-2">{{ $dnsRecords['spf']['description'] }}</p>
                            @if (!empty($dnsRecords['spf']['value']))
                                <div class="bg-gray-50 p-3 rounded font-mono text-sm break-all">
                                    {{ $dnsRecords['spf']['value'] }}
                                </div>
                            @endif
                            @if ($dnsRecords['spf']['status'] == 'fail' && !empty($dnsRecords['spf']['recommended']))
                                <div class="mt-2 p-3 bg-yellow-50 rounded">
                                    <p class="text-sm"><strong>Recommended TXT record:</strong></p>
                                    <div class="bg-white p-2 rounded font-mono text-xs mt-1 break-all">
                                        {{ $dnsRecords['spf']['recommended'] }}
                                    </div>
                                </div>
                            @endif
                        </div>
                    </div>

                    <!-- DKIM Record -->
                    <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                        <div class="p-6">
                            <h3 class="text-lg font-semibold mb-2 flex items-center">
                                DKIM (DomainKeys Identified Mail)
                                @if ($dnsRecords['dkim']['status'] == 'pass')
                                    <svg class="h-5 w-5 text-green-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                                    </svg>
                                @else
                                    <svg class="h-5 w-5 text-red-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                                    </svg>
                                @endif
                            </h3>
                            <p class="text-sm text-gray-600 mb-2">{{ $dnsRecords['dkim']['description'] }}</p>
                            @if (!empty($dnsRecords['dkim']['selector']))
                                <p class="text-sm mb-2"><strong>Selector:</strong> {{ $dnsRecords['dkim']['selector'] }}</p>
                            @endif
                            @if (!empty($dnsRecords['dkim']['value']))
                                <div class="bg-gray-50 p-3 rounded font-mono text-xs break-all">
                                    {{ $dnsRecords['dkim']['value'] }}
                                </div>
                            @endif
                        </div>
                    </div>

                    <!-- DMARC Record -->
                    <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                        <div class="p-6">
                            <h3 class="text-lg font-semibold mb-2 flex items-center">
                                DMARC (Domain-based Message Authentication)
                                @if ($dnsRecords['dmarc']['status'] == 'pass')
                                    <svg class="h-5 w-5 text-green-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                                    </svg>
                                @else
                                    <svg class="h-5 w-5 text-red-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                                    </svg>
                                @endif
                            </h3>
                            <p class="text-sm text-gray-600 mb-2">{{ $dnsRecords['dmarc']['description'] }}</p>
                            @if (!empty($dnsRecords['dmarc']['value']))
                                <div class="bg-gray-50 p-3 rounded font-mono text-sm break-all">
                                    {{ $dnsRecords['dmarc']['value'] }}
                                </div>
                            @endif
                            @if ($dnsRecords['dmarc']['status'] == 'fail' && !empty($dnsRecords['dmarc']['recommended']))
                                <div class="mt-2 p-3 bg-yellow-50 rounded">
                                    <p class="text-sm"><strong>Recommended TXT record at _dmarc.{{ request('domain') }}:</strong></p>
                                    <div class="bg-white p-2 rounded font-mono text-xs mt-1 break-all">
                                        {{ $dnsRecords['dmarc']['recommended'] }}
                                    </div>
                                </div>
                            @endif
                        </div>
                    </div>

                    <!-- PTR Record (Reverse DNS) -->
                    <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                        <div class="p-6">
                            <h3 class="text-lg font-semibold mb-2 flex items-center">
                                PTR (Reverse DNS)
                                @if ($dnsRecords['ptr']['status'] == 'pass')
                                    <svg class="h-5 w-5 text-green-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                                    </svg>
                                @elseif ($dnsRecords['ptr']['status'] == 'warning')
                                    <svg class="h-5 w-5 text-yellow-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
                                    </svg>
                                @else
                                    <svg class="h-5 w-5 text-red-600 ml-2" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                                    </svg>
                                @endif
                            </h3>
                            <p class="text-sm text-gray-600 mb-2">{{ $dnsRecords['ptr']['description'] }}</p>
                            @if (!empty($dnsRecords['ptr']['value']))
                                <div class="bg-gray-50 p-3 rounded font-mono text-sm">
                                    {{ $dnsRecords['ptr']['value'] }}
                                </div>
                            @endif
                            @if ($dnsRecords['ptr']['status'] != 'pass')
                                <div class="mt-2 p-3 bg-yellow-50 rounded">
                                    <p class="text-sm text-yellow-800">
                                        <strong>Note:</strong> PTR record must be configured by your hosting provider. 
                                        Contact them to set reverse DNS to point to your mail server hostname.
                                    </p>
                                </div>
                            @endif
                        </div>
                    </div>
                </div>

                <!-- DNS Configuration Help -->
                <div class="mt-6 bg-blue-50 border-l-4 border-blue-400 p-4">
                    <h3 class="text-sm font-medium text-blue-800 mb-2">DNS Configuration Instructions</h3>
                    <div class="text-sm text-blue-700 space-y-2">
                        <p>Add these records in your domain's DNS management panel (e.g., Cloudflare, GoDaddy, Namecheap):</p>
                        <ul class="list-disc list-inside ml-4 space-y-1">
                            <li><strong>MX Record:</strong> Priority 10, Value: {{ request()->getHost() }}</li>
                            <li><strong>A Record:</strong> @ (or domain name), Value: Server IP</li>
                            <li><strong>SPF TXT Record:</strong> v=spf1 mx ~all</li>
                            <li><strong>DKIM TXT Record:</strong> Get public key from /etc/opendkim/keys/[domain]/default.txt</li>
                            <li><strong>DMARC TXT Record:</strong> v=DMARC1; p=quarantine; rua=mailto:postmaster@{{ request('domain') }}</li>
                        </ul>
                        <p class="mt-2"><strong>Important:</strong> DNS changes can take up to 48 hours to propagate globally.</p>
                    </div>
                </div>
            @else
                <div class="bg-gray-50 p-8 rounded-lg text-center">
                    <svg class="h-16 w-16 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                    </svg>
                    <p class="text-gray-600">Select a domain to check DNS configuration</p>
                </div>
            @endif
        </div>
    </div>
</x-app-layout>
