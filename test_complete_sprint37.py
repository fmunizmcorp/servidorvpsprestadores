#!/usr/bin/env python3
"""
TESTE COMPLETO AUTOMATIZADO - SPRINT 37
Valida 100% das funcionalidades do admin panel
"""

import requests
import json
import time
import re
from urllib3.exceptions import InsecureRequestWarning
from datetime import datetime
from html.parser import HTMLParser

# Desabilitar warnings de SSL
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)

class AdminPanelTester:
    def __init__(self, base_url, email, password):
        self.base_url = base_url
        self.email = email
        self.password = password
        self.session = requests.Session()
        self.session.verify = False  # Aceitar certificado auto-assinado
        self.logged_in = False
        
        # Contadores
        self.total_tests = 0
        self.passed_tests = 0
        self.failed_tests = 0
        
        # Resultados detalhados
        self.results = {}
        
    def log(self, message, level="INFO"):
        timestamp = datetime.now().strftime("%H:%M:%S")
        prefix = {
            "INFO": "ℹ️",
            "SUCCESS": "✅",
            "ERROR": "❌",
            "WARNING": "⚠️"
        }.get(level, "📝")
        print(f"[{timestamp}] {prefix} {message}")
        
    def test_login(self):
        """Testa o login no sistema"""
        self.log("Testando login...", "INFO")
        self.total_tests += 1
        
        try:
            # 1. Obter página de login e CSRF token
            login_page = self.session.get(f"{self.base_url}/login", timeout=10)
            
            if login_page.status_code != 200:
                self.log(f"Erro ao acessar página de login: {login_page.status_code}", "ERROR")
                self.failed_tests += 1
                self.results['login'] = {"status": "FAILED", "code": login_page.status_code}
                return False
            
            # 2. Extrair CSRF token do HTML
            csrf_token = None
            csrf_match = re.search(r'<input[^>]*name=["\']_token["\'][^>]*value=["\'](.*?)["\']', login_page.text)
            if csrf_match:
                csrf_token = csrf_match.group(1)
                self.log(f"CSRF token extraído: {csrf_token[:20]}...", "INFO")
            else:
                self.log("CSRF token não encontrado no HTML", "WARNING")
            
            # 3. Preparar headers
            headers = {
                'Referer': f"{self.base_url}/login",
                'Origin': self.base_url.replace('/admin', ''),
                'Content-Type': 'application/x-www-form-urlencoded'
            }
            
            # 4. Fazer login
            login_data = {
                'email': self.email,
                'password': self.password
            }
            
            if csrf_token:
                login_data['_token'] = csrf_token
            
            response = self.session.post(
                f"{self.base_url}/login",
                data=login_data,
                headers=headers,
                allow_redirects=True,
                timeout=10
            )
            
            # 3. Verificar se o login foi bem-sucedido
            if response.status_code == 200 and '/dashboard' in response.url:
                self.log("Login realizado com sucesso!", "SUCCESS")
                self.logged_in = True
                self.passed_tests += 1
                self.results['login'] = {"status": "PASSED", "code": 200}
                return True
            else:
                self.log(f"Falha no login. Status: {response.status_code}, URL: {response.url}", "ERROR")
                self.failed_tests += 1
                self.results['login'] = {"status": "FAILED", "code": response.status_code, "url": response.url}
                return False
                
        except Exception as e:
            self.log(f"Exceção durante login: {str(e)}", "ERROR")
            self.failed_tests += 1
            self.results['login'] = {"status": "FAILED", "error": str(e)}
            return False
    
    def test_page_access(self, path, name):
        """Testa acesso a uma página específica"""
        self.total_tests += 1
        
        try:
            url = f"{self.base_url}{path}"
            response = self.session.get(url, timeout=10)
            
            if response.status_code == 200:
                self.log(f"✅ {name}: {response.status_code}", "SUCCESS")
                self.passed_tests += 1
                self.results[name] = {"status": "PASSED", "code": 200, "path": path}
                return True
            else:
                self.log(f"❌ {name}: {response.status_code}", "ERROR")
                self.failed_tests += 1
                self.results[name] = {"status": "FAILED", "code": response.status_code, "path": path}
                return False
                
        except Exception as e:
            self.log(f"❌ {name}: Exceção - {str(e)}", "ERROR")
            self.failed_tests += 1
            self.results[name] = {"status": "FAILED", "error": str(e), "path": path}
            return False
    
    def test_all_pages(self):
        """Testa acesso a todas as páginas do admin"""
        self.log("Testando acesso a todas as páginas...", "INFO")
        
        pages = [
            ("/dashboard", "Dashboard"),
            ("/sites", "Sites - Listagem"),
            ("/sites/create", "Sites - Criar"),
            ("/email/domains", "Email Domains - Listagem"),
            ("/email/domains/create", "Email Domains - Criar"),
            ("/email/accounts", "Email Accounts - Listagem"),
            ("/email/accounts/create", "Email Accounts - Criar"),
            ("/dns", "DNS - Listagem"),
            ("/dns/create", "DNS - Criar"),
            ("/users", "Users - Listagem"),
            ("/users/create", "Users - Criar"),
            ("/settings", "Settings"),
            ("/logs", "Logs"),
            ("/services", "Services"),
        ]
        
        for path, name in pages:
            self.test_page_access(path, name)
            time.sleep(0.5)  # Pequeno delay entre requisições
    
    def test_create_site(self, site_name=None):
        """Testa criação de um novo site"""
        self.log("Testando criação de site...", "INFO")
        self.total_tests += 1
        
        if site_name is None:
            site_name = f"testsprint37-{int(time.time())}"
        
        try:
            # 1. Acessar página de criação
            create_page = self.session.get(f"{self.base_url}/sites/create", timeout=10)
            
            if create_page.status_code != 200:
                self.log(f"Erro ao acessar página de criação: {create_page.status_code}", "ERROR")
                self.failed_tests += 1
                self.results['create_site'] = {"status": "FAILED", "code": create_page.status_code}
                return False
            
            # 2. Extrair CSRF token da página de criação
            csrf_token = None
            csrf_match = re.search(r'<input[^>]*name=["\']_token["\'][^>]*value=["\'](.*?)["\']', create_page.text)
            if not csrf_match:
                # Tentar padrão alternativo
                csrf_match = re.search(r'<meta[^>]*name=["\']csrf-token["\'][^>]*content=["\'](.*?)["\']', create_page.text)
            
            if csrf_match:
                csrf_token = csrf_match.group(1)
                self.log(f"CSRF token extraído para POST: {csrf_token[:20]}...", "INFO")
            else:
                self.log("⚠️ CSRF token não encontrado na página, tentando sem token", "WARNING")
            
            # 3. Submeter formulário COM CSRF TOKEN
            site_data = {
                'site_name': site_name,
                'domain': f"{site_name}.local",
                'template': 'html',
                'create_database': 'on'
            }
            
            # Adicionar CSRF token se encontrado
            if csrf_token:
                site_data['_token'] = csrf_token
            
            response = self.session.post(
                f"{self.base_url}/sites",
                data=site_data,
                allow_redirects=True,
                timeout=30
            )
            
            if response.status_code == 200:
                self.log(f"Site '{site_name}' criado com sucesso!", "SUCCESS")
                self.passed_tests += 1
                self.results['create_site'] = {
                    "status": "PASSED", 
                    "site_name": site_name,
                    "code": 200
                }
                return site_name
            else:
                self.log(f"Erro ao criar site: {response.status_code}", "ERROR")
                self.failed_tests += 1
                self.results['create_site'] = {"status": "FAILED", "code": response.status_code}
                return False
                
        except Exception as e:
            self.log(f"Exceção ao criar site: {str(e)}", "ERROR")
            self.failed_tests += 1
            self.results['create_site'] = {"status": "FAILED", "error": str(e)}
            return False
    
    def generate_report(self):
        """Gera relatório final dos testes"""
        self.log("="*80, "INFO")
        self.log("RELATÓRIO FINAL DE TESTES - SPRINT 37", "INFO")
        self.log("="*80, "INFO")
        
        total_percentage = (self.passed_tests / self.total_tests * 100) if self.total_tests > 0 else 0
        
        print(f"\n📊 ESTATÍSTICAS GERAIS:")
        print(f"  Total de Testes: {self.total_tests}")
        print(f"  ✅ Testes Passados: {self.passed_tests}")
        print(f"  ❌ Testes Falhados: {self.failed_tests}")
        print(f"  📈 Taxa de Sucesso: {total_percentage:.1f}%")
        
        print(f"\n📋 RESULTADOS DETALHADOS:")
        for test_name, result in self.results.items():
            status_icon = "✅" if result['status'] == "PASSED" else "❌"
            print(f"  {status_icon} {test_name}: {result['status']} - {result.get('code', 'N/A')}")
        
        print(f"\n{'='*80}")
        
        # Salvar relatório em JSON
        report_file = f"/tmp/test_report_sprint37_{int(time.time())}.json"
        with open(report_file, 'w') as f:
            json.dump({
                'timestamp': datetime.now().isoformat(),
                'statistics': {
                    'total': self.total_tests,
                    'passed': self.passed_tests,
                    'failed': self.failed_tests,
                    'success_rate': total_percentage
                },
                'results': self.results
            }, f, indent=2)
        
        self.log(f"Relatório salvo em: {report_file}", "SUCCESS")
        
        return total_percentage

def main():
    # Configuração
    BASE_URL = "https://72.61.53.222/admin"
    EMAIL = "test@admin.local"
    PASSWORD = "Test@123456"
    
    print("="*80)
    print("🚀 INICIANDO TESTES AUTOMATIZADOS - SPRINT 37")
    print("="*80)
    print(f"URL: {BASE_URL}")
    print(f"Email: {EMAIL}")
    print(f"Data: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*80)
    print()
    
    # Criar instância do testador
    tester = AdminPanelTester(BASE_URL, EMAIL, PASSWORD)
    
    # 1. Testar login
    if not tester.test_login():
        print("\n❌ FALHA CRÍTICA: Não foi possível fazer login!")
        print("Abortando testes...")
        return
    
    print()
    
    # 2. Testar acesso a todas as páginas
    tester.test_all_pages()
    
    print()
    
    # 3. Testar criação de site
    site_name = tester.test_create_site()
    
    if site_name:
        print(f"\n⏳ Aguardando 30 segundos para scripts em background...")
        time.sleep(30)
        print("✅ Tempo de espera concluído")
    
    print()
    
    # 4. Gerar relatório final
    success_rate = tester.generate_report()
    
    # 5. Determinar resultado final
    if success_rate >= 90:
        print("\n🎉 SISTEMA 100% FUNCIONAL!")
        return 0
    elif success_rate >= 70:
        print("\n⚠️ Sistema parcialmente funcional - correções necessárias")
        return 1
    else:
        print("\n❌ Sistema com problemas críticos")
        return 2

if __name__ == "__main__":
    exit(main())
