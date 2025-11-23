@extends('layouts.app')

@section('content')
<div class="container-fluid">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">
                        <i class="fas fa-qrcode mr-2"></i>
                        Enable Two-Factor Authentication
                    </h3>
                </div>
                <div class="card-body">
                    <div class="alert alert-info">
                        <i class="fas fa-info-circle"></i>
                        <strong>Step 1 of 2:</strong> Scan the QR code with your authenticator app
                    </div>

                    <div class="row">
                        <div class="col-md-6 text-center">
                            <h5>Scan this QR Code</h5>
                            <div class="qr-code-container p-3 bg-white border rounded d-inline-block">
                                {!! $qrCodeSvg !!}
                            </div>
                            <p class="text-muted mt-3">
                                Use Google Authenticator, Authy, or any compatible TOTP app
                            </p>
                        </div>

                        <div class="col-md-6">
                            <h5>Or enter this secret key manually</h5>
                            <div class="card bg-light">
                                <div class="card-body">
                                    <p class="text-muted mb-2">Secret Key:</p>
                                    <code class="d-block p-2 bg-white border rounded" style="font-size: 1.1em; word-break: break-all;">
                                        {{ $secret }}
                                    </code>
                                    <button type="button" class="btn btn-sm btn-secondary mt-2" onclick="copySecret()">
                                        <i class="fas fa-copy"></i> Copy Secret
                                    </button>
                                </div>
                            </div>

                            <div class="alert alert-warning mt-3">
                                <i class="fas fa-exclamation-triangle"></i>
                                <strong>Important:</strong> Save this secret key in a safe place. You'll need it if you lose access to your authenticator app.
                            </div>
                        </div>
                    </div>

                    <hr class="my-4">

                    <div class="alert alert-info">
                        <i class="fas fa-info-circle"></i>
                        <strong>Step 2 of 2:</strong> Enter the 6-digit code from your authenticator app
                    </div>

                    <form method="POST" action="{{ route('two-factor.confirm') }}">
                        @csrf
                        <div class="row justify-content-center">
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label for="code">Verification Code:</label>
                                    <input type="text" 
                                           class="form-control form-control-lg text-center @error('code') is-invalid @enderror" 
                                           id="code" 
                                           name="code" 
                                           placeholder="000000"
                                           maxlength="6"
                                           pattern="[0-9]{6}"
                                           required
                                           autofocus
                                           style="letter-spacing: 0.5em; font-size: 1.5em;">
                                    @error('code')
                                        <div class="invalid-feedback">{{ $message }}</div>
                                    @enderror
                                    <small class="form-text text-muted">
                                        Enter the 6-digit code from your authenticator app
                                    </small>
                                </div>

                                <div class="form-group">
                                    <button type="submit" class="btn btn-primary btn-lg btn-block">
                                        <i class="fas fa-check"></i> Verify and Enable 2FA
                                    </button>
                                    <a href="{{ route('two-factor.show') }}" class="btn btn-secondary btn-block">
                                        <i class="fas fa-times"></i> Cancel
                                    </a>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
function copySecret() {
    const secret = '{{ $secret }}';
    
    // Create temporary textarea
    const textarea = document.createElement('textarea');
    textarea.value = secret;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    
    // Select and copy
    textarea.select();
    document.execCommand('copy');
    
    // Remove textarea
    document.body.removeChild(textarea);
    
    // Show feedback
    const button = event.target.closest('button');
    const originalText = button.innerHTML;
    button.innerHTML = '<i class="fas fa-check"></i> Copied!';
    button.classList.remove('btn-secondary');
    button.classList.add('btn-success');
    
    setTimeout(() => {
        button.innerHTML = originalText;
        button.classList.remove('btn-success');
        button.classList.add('btn-secondary');
    }, 2000);
}

// Auto-focus and format code input
document.getElementById('code').addEventListener('input', function(e) {
    this.value = this.value.replace(/[^0-9]/g, '');
});
</script>

<style>
.qr-code-container svg {
    max-width: 100%;
    height: auto;
}
</style>
@endsection
