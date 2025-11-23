#!/usr/bin/env python3
"""
Teste autenticado completo das operações de Sites e Email Domains
"""
import requests
import json
from urllib3.exceptions import InsecureRequestWarning
from datetime import datetime

# Suprimir avisos SSL
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)

# Configurações
BASE_URL = "https://72.61.53.222/admin"
EMAIL = "admin@localhost"
PASSWORD = "Admin@2025!"

class TestSuite:
    def __init__(self):
        self.session = requests.Session()
        self.session.verify = False  # Ignorar SSL para testes
        self.csrf_token = None
        
    def get_csrf_token(self, url):
        """Extrai CSRF token de uma página"""
        response = self.session.get(url)
        # Procurar por: <input type="hidden" name="_token" value="TOKEN">
        import re
        match = re.search(r'name="_token"\s+value="([^"]+)"', response.text)
        if match:
            return match.group(1)
        return None
    
    def login(self):
        """Realiza login no sistema"""
        print(f"\n{'='*60}")
        print("TEST 1: LOGIN")
        print(f"{'='*60}")
        
        login_url = f"{BASE_URL}/login"
        print(f"📋 Acessando página de login: {login_url}")
        
        # Obter CSRF token
        self.csrf_token = self.get_csrf_token(login_url)
        if not self.csrf_token:
            print("❌ FALHA: Não conseguiu obter CSRF token")
            return False
            
        print(f"✅ CSRF Token obtido: {self.csrf_token[:20]}...")
        
        # Fazer login
        login_data = {
            '_token': self.csrf_token,
            'email': EMAIL,
            'password': PASSWORD,
            'remember': 'on'
        }
        
        response = self.session.post(login_url, data=login_data, allow_redirects=False)
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 302:
            print(f"✅ LOGIN SUCESSO - Redirecionado para: {response.headers.get('Location', 'N/A')}")
            return True
        else:
            print(f"❌ LOGIN FALHOU - Status: {response.status_code}")
            print(f"Response: {response.text[:200]}")
            return False
    
    def test_sites_page(self):
        """Testa acesso à página de sites"""
        print(f"\n{'='*60}")
        print("TEST 2: ACESSO À PÁGINA DE SITES")
        print(f"{'='*60}")
        
        sites_url = f"{BASE_URL}/sites"
        print(f"📋 Acessando: {sites_url}")
        
        response = self.session.get(sites_url)
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ PÁGINA DE SITES ACESSÍVEL")
            # Verificar se o formulário está presente
            if 'form' in response.text.lower():
                print("✅ Formulário de criação detectado na página")
            return True
        else:
            print(f"❌ FALHA - Status: {response.status_code}")
            return False
    
    def test_create_site(self):
        """Testa criação de um novo site"""
        print(f"\n{'='*60}")
        print("TEST 3: CRIAR NOVO SITE")
        print(f"{'='*60}")
        
        # Obter CSRF token da página de sites
        sites_url = f"{BASE_URL}/sites"
        self.csrf_token = self.get_csrf_token(sites_url)
        
        if not self.csrf_token:
            print("❌ FALHA: Não conseguiu obter CSRF token da página de sites")
            return False
        
        # Dados do site de teste
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        site_data = {
            '_token': self.csrf_token,
            'site_name': f'teste_validacao_{timestamp}',
            'domain': f'teste-{timestamp}.mcorp.local',
            'php_version': '8.2'
        }
        
        print(f"📋 Criando site: {site_data['site_name']}")
        print(f"   Domínio: {site_data['domain']}")
        print(f"   PHP: {site_data['php_version']}")
        
        # Fazer POST
        response = self.session.post(sites_url, data=site_data, allow_redirects=False)
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 302:
            print(f"✅ SITE CRIADO COM SUCESSO - Redirecionado para: {response.headers.get('Location', 'N/A')}")
            # Verificar se há mensagem de sucesso na sessão
            redirect_response = self.session.get(f"{BASE_URL}/sites")
            if 'success' in redirect_response.text.lower() or 'sucesso' in redirect_response.text.lower():
                print("✅ Mensagem de sucesso detectada")
            return True
        elif response.status_code == 200:
            # Pode ser que retornou a página com erro
            if 'error' in response.text.lower() or 'erro' in response.text.lower():
                print("❌ FALHA - Erro detectado na resposta")
                # Tentar extrair mensagem de erro
                import re
                error_match = re.search(r'<div[^>]*class="[^"]*alert[^"]*"[^>]*>([^<]+)', response.text)
                if error_match:
                    print(f"   Mensagem: {error_match.group(1).strip()}")
            else:
                print("⚠️  Retornou 200 mas sem indicação clara de erro")
            return False
        else:
            print(f"❌ FALHA - Status inesperado: {response.status_code}")
            print(f"Response: {response.text[:300]}")
            return False
    
    def test_email_domains_page(self):
        """Testa acesso à página de domínios de email"""
        print(f"\n{'='*60}")
        print("TEST 4: ACESSO À PÁGINA DE DOMÍNIOS DE EMAIL")
        print(f"{'='*60}")
        
        email_url = f"{BASE_URL}/email/domains"
        print(f"📋 Acessando: {email_url}")
        
        response = self.session.get(email_url)
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ PÁGINA DE EMAIL DOMAINS ACESSÍVEL")
            if 'form' in response.text.lower():
                print("✅ Formulário de criação detectado na página")
            return True
        else:
            print(f"❌ FALHA - Status: {response.status_code}")
            return False
    
    def test_create_email_domain(self):
        """Testa criação de um novo domínio de email"""
        print(f"\n{'='*60}")
        print("TEST 5: CRIAR NOVO DOMÍNIO DE EMAIL")
        print(f"{'='*60}")
        
        # Obter CSRF token
        email_url = f"{BASE_URL}/email/domains"
        self.csrf_token = self.get_csrf_token(email_url)
        
        if not self.csrf_token:
            print("❌ FALHA: Não conseguiu obter CSRF token")
            return False
        
        # Dados do domínio de teste
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        domain_data = {
            '_token': self.csrf_token,
            'domain': f'email-test-{timestamp}.com'
        }
        
        print(f"📋 Criando domínio: {domain_data['domain']}")
        
        # Fazer POST
        response = self.session.post(email_url, data=domain_data, allow_redirects=False)
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 302:
            print(f"✅ DOMÍNIO CRIADO COM SUCESSO - Redirecionado para: {response.headers.get('Location', 'N/A')}")
            return True
        elif response.status_code == 200:
            if 'error' in response.text.lower() or 'erro' in response.text.lower():
                print("❌ FALHA - Erro detectado na resposta")
            else:
                print("⚠️  Retornou 200 mas sem indicação clara de erro")
            return False
        else:
            print(f"❌ FALHA - Status: {response.status_code}")
            return False
    
    def run_all_tests(self):
        """Executa todos os testes"""
        print("\n" + "="*60)
        print(" SUITE DE TESTES - VALIDAÇÃO COMPLETA")
        print("="*60)
        
        results = {
            'login': False,
            'sites_page': False,
            'create_site': False,
            'email_domains_page': False,
            'create_email_domain': False
        }
        
        # Test 1: Login
        results['login'] = self.login()
        if not results['login']:
            print("\n❌ LOGIN FALHOU - Não é possível continuar os testes")
            self.print_summary(results)
            return results
        
        # Test 2: Sites page
        results['sites_page'] = self.test_sites_page()
        
        # Test 3: Create site
        results['create_site'] = self.test_create_site()
        
        # Test 4: Email domains page
        results['email_domains_page'] = self.test_email_domains_page()
        
        # Test 5: Create email domain
        results['create_email_domain'] = self.test_create_email_domain()
        
        # Imprimir resumo
        self.print_summary(results)
        
        return results
    
    def print_summary(self, results):
        """Imprime resumo dos testes"""
        print(f"\n{'='*60}")
        print(" RESUMO DOS TESTES")
        print(f"{'='*60}")
        
        total = len(results)
        passed = sum(1 for v in results.values() if v)
        
        for test_name, passed_test in results.items():
            status = "✅ PASSOU" if passed_test else "❌ FALHOU"
            print(f"{status} - {test_name.replace('_', ' ').upper()}")
        
        print(f"\n{'='*60}")
        percentage = (passed / total) * 100
        print(f"RESULTADO FINAL: {passed}/{total} testes passaram ({percentage:.1f}%)")
        print(f"{'='*60}\n")
        
        if percentage == 100:
            print("🎉 SUCESSO COMPLETO! Todos os testes passaram!")
        elif percentage >= 80:
            print("⚠️  Quase lá! Alguns testes falharam.")
        else:
            print("❌ Problemas críticos detectados.")

if __name__ == "__main__":
    suite = TestSuite()
    results = suite.run_all_tests()
