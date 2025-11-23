@extends('layouts.app')

@section('content')
<div class="container-fluid">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header bg-success text-white">
                    <h3 class="card-title">
                        <i class="fas fa-check-circle mr-2"></i>
                        @if(isset($regenerated) && $regenerated)
                            Recovery Codes Regenerated!
                        @else
                            Two-Factor Authentication Enabled!
                        @endif
                    </h3>
                </div>
                <div class="card-body">
                    @if(isset($regenerated) && $regenerated)
                        <div class="alert alert-success">
                            <i class="fas fa-sync-alt"></i>
                            <strong>Your recovery codes have been regenerated.</strong>
                            <p class="mb-0 mt-2">Your old recovery codes are no longer valid. Please save these new codes.</p>
                        </div>
                    @else
                        <div class="alert alert-success">
                            <i class="fas fa-check-circle"></i>
                            <strong>Two-factor authentication is now enabled on your account!</strong>
                            <p class="mb-0 mt-2">Your account is now more secure.</p>
                        </div>
                    @endif

                    <div class="alert alert-warning">
                        <i class="fas fa-exclamation-triangle"></i>
                        <strong>IMPORTANT: Save your recovery codes!</strong>
                        <p class="mb-0">These codes can be used to access your account if you lose your authenticator device. Each code can only be used once.</p>
                    </div>

                    <div class="card bg-light">
                        <div class="card-header">
                            <h5 class="mb-0">
                                <i class="fas fa-key"></i> Your Recovery Codes
                            </h5>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                @foreach($recoveryCodes as $code)
                                <div class="col-md-6 mb-2">
                                    <div class="border rounded p-2 bg-white">
                                        <code style="font-size: 1.1em;">{{ substr($code, 0, 5) }}-{{ substr($code, 5) }}</code>
                                    </div>
                                </div>
                                @endforeach
                            </div>

                            <div class="mt-3">
                                <button type="button" class="btn btn-primary" onclick="copyAllCodes()">
                                    <i class="fas fa-copy"></i> Copy All Codes
                                </button>
                                <button type="button" class="btn btn-secondary" onclick="downloadCodes()">
                                    <i class="fas fa-download"></i> Download as Text File
                                </button>
                                <button type="button" class="btn btn-info" onclick="window.print()">
                                    <i class="fas fa-print"></i> Print Codes
                                </button>
                            </div>
                        </div>
                    </div>

                    <div class="alert alert-info mt-4">
                        <i class="fas fa-info-circle"></i>
                        <strong>How to use recovery codes:</strong>
                        <ul class="mb-0 mt-2">
                            <li>Save these codes in a secure location (password manager, safe, etc.)</li>
                            <li>You can use a recovery code instead of your authenticator code during login</li>
                            <li>Each code can only be used once</li>
                            <li>You can regenerate new codes at any time from your 2FA settings</li>
                        </ul>
                    </div>

                    <div class="text-center mt-4">
                        <a href="{{ route('dashboard') }}" class="btn btn-success btn-lg">
                            <i class="fas fa-home"></i> Go to Dashboard
                        </a>
                        <a href="{{ route('two-factor.show') }}" class="btn btn-outline-primary btn-lg">
                            <i class="fas fa-cog"></i> 2FA Settings
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
const recoveryCodes = @json($recoveryCodes);

function copyAllCodes() {
    const codes = recoveryCodes.map(code => {
        return code.substr(0, 5) + '-' + code.substr(5);
    }).join('\n');
    
    const textarea = document.createElement('textarea');
    textarea.value = codes;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
    
    const button = event.target.closest('button');
    const originalText = button.innerHTML;
    button.innerHTML = '<i class="fas fa-check"></i> Copied!';
    button.classList.remove('btn-primary');
    button.classList.add('btn-success');
    
    setTimeout(() => {
        button.innerHTML = originalText;
        button.classList.remove('btn-success');
        button.classList.add('btn-primary');
    }, 2000);
}

function downloadCodes() {
    const codes = recoveryCodes.map(code => {
        return code.substr(0, 5) + '-' + code.substr(5);
    }).join('\n');
    
    const content = `VPS Admin Panel - Two-Factor Authentication Recovery Codes
Generated: ${new Date().toLocaleString()}

IMPORTANT: Keep these codes in a safe place!
Each code can only be used once.

Your Recovery Codes:
${codes}

Instructions:
- Use these codes if you lose access to your authenticator app
- Enter a recovery code instead of your 6-digit code during login
- After using all codes, regenerate new ones from your 2FA settings
`;
    
    const blob = new Blob([content], { type: 'text/plain' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'vps-admin-2fa-recovery-codes.txt';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
}
</script>

<style>
@media print {
    .btn, .alert, nav, .main-sidebar, .main-header, .main-footer {
        display: none !important;
    }
    .content-wrapper {
        margin: 0 !important;
        padding: 0 !important;
    }
}
</style>
@endsection
