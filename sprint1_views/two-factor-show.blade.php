@extends('layouts.app')

@section('content')
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">
                        <i class="fas fa-shield-alt mr-2"></i>
                        Two-Factor Authentication (2FA)
                    </h3>
                </div>
                <div class="card-body">
                    @if(session('success'))
                        <div class="alert alert-success alert-dismissible fade show">
                            {{ session('success') }}
                            <button type="button" class="close" data-dismiss="alert">&times;</button>
                        </div>
                    @endif

                    @if(session('warning'))
                        <div class="alert alert-warning alert-dismissible fade show">
                            {{ session('warning') }}
                            <button type="button" class="close" data-dismiss="alert">&times;</button>
                        </div>
                    @endif

                    @if($enabled)
                        <div class="alert alert-success">
                            <i class="fas fa-check-circle"></i>
                            <strong>Two-Factor Authentication is ENABLED</strong>
                            <p class="mb-0 mt-2">Your account is protected with two-factor authentication.</p>
                        </div>

                        <div class="row mt-4">
                            <div class="col-md-6">
                                <div class="card bg-light">
                                    <div class="card-body">
                                        <h5><i class="fas fa-key"></i> Regenerate Recovery Codes</h5>
                                        <p class="text-muted">If you've lost your recovery codes or used them, you can generate new ones.</p>
                                        <button type="button" class="btn btn-warning" data-toggle="modal" data-target="#regenerateModal">
                                            <i class="fas fa-sync-alt"></i> Regenerate Codes
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <div class="col-md-6">
                                <div class="card bg-light">
                                    <div class="card-body">
                                        <h5><i class="fas fa-times-circle"></i> Disable 2FA</h5>
                                        <p class="text-muted">You can disable two-factor authentication at any time.</p>
                                        <button type="button" class="btn btn-danger" data-toggle="modal" data-target="#disableModal">
                                            <i class="fas fa-ban"></i> Disable 2FA
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Disable 2FA Modal -->
                        <div class="modal fade" id="disableModal" tabindex="-1">
                            <div class="modal-dialog">
                                <div class="modal-content">
                                    <form method="POST" action="{{ route('two-factor.disable') }}">
                                        @csrf
                                        <div class="modal-header bg-danger text-white">
                                            <h5 class="modal-title">Disable Two-Factor Authentication</h5>
                                            <button type="button" class="close text-white" data-dismiss="modal">&times;</button>
                                        </div>
                                        <div class="modal-body">
                                            <div class="alert alert-warning">
                                                <i class="fas fa-exclamation-triangle"></i>
                                                <strong>Warning!</strong> Disabling 2FA will make your account less secure.
                                            </div>
                                            <div class="form-group">
                                                <label for="disable_password">Confirm your password:</label>
                                                <input type="password" class="form-control @error('password') is-invalid @enderror" 
                                                       id="disable_password" name="password" required>
                                                @error('password')
                                                    <div class="invalid-feedback">{{ $message }}</div>
                                                @enderror
                                            </div>
                                        </div>
                                        <div class="modal-footer">
                                            <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                                            <button type="submit" class="btn btn-danger">Disable 2FA</button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>

                        <!-- Regenerate Recovery Codes Modal -->
                        <div class="modal fade" id="regenerateModal" tabindex="-1">
                            <div class="modal-dialog">
                                <div class="modal-content">
                                    <form method="POST" action="{{ route('two-factor.regenerate-codes') }}">
                                        @csrf
                                        <div class="modal-header bg-warning">
                                            <h5 class="modal-title">Regenerate Recovery Codes</h5>
                                            <button type="button" class="close" data-dismiss="modal">&times;</button>
                                        </div>
                                        <div class="modal-body">
                                            <div class="alert alert-info">
                                                <i class="fas fa-info-circle"></i>
                                                Your old recovery codes will be invalidated and replaced with new ones.
                                            </div>
                                            <div class="form-group">
                                                <label for="regenerate_password">Confirm your password:</label>
                                                <input type="password" class="form-control @error('password') is-invalid @enderror" 
                                                       id="regenerate_password" name="password" required>
                                                @error('password')
                                                    <div class="invalid-feedback">{{ $message }}</div>
                                                @enderror
                                            </div>
                                        </div>
                                        <div class="modal-footer">
                                            <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                                            <button type="submit" class="btn btn-warning">Regenerate Codes</button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>

                    @else
                        <div class="alert alert-warning">
                            <i class="fas fa-exclamation-triangle"></i>
                            <strong>Two-Factor Authentication is DISABLED</strong>
                            <p class="mb-0 mt-2">Enable 2FA to add an extra layer of security to your account.</p>
                        </div>

                        <div class="card bg-light mt-4">
                            <div class="card-body">
                                <h5><i class="fas fa-mobile-alt"></i> What is Two-Factor Authentication?</h5>
                                <p>Two-factor authentication (2FA) adds an extra layer of security to your account. In addition to your password, you'll need to enter a 6-digit code from your authenticator app.</p>
                                
                                <h6 class="mt-3">How it works:</h6>
                                <ol>
                                    <li>Download an authenticator app (Google Authenticator, Authy, etc.)</li>
                                    <li>Scan the QR code we'll provide</li>
                                    <li>Enter the 6-digit code from your app to confirm setup</li>
                                    <li>Save your recovery codes in a safe place</li>
                                </ol>

                                <a href="{{ route('two-factor.enable') }}" class="btn btn-primary btn-lg mt-3">
                                    <i class="fas fa-lock"></i> Enable Two-Factor Authentication
                                </a>
                            </div>
                        </div>
                    @endif
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
