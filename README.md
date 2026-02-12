# Webscraping Manager

Sistema principal do projeto de web scraping de anúncios de veículos. Gerencia tarefas de coleta, autentica usuários via microsserviço de autenticação e envia notificações ao microsserviço de notificações.

## Responsabilidade

- **Autenticação**: Telas de login e registro consumindo o auth-service; proteção de rotas (apenas usuários autenticados).
- **Tarefas de Scraping**: Criar (informando URL do anúncio Webmotors), listar, visualizar detalhes/resultado e excluir tarefas.
- **Scraping**: Processamento assíncrono (Sidekiq + Selenium WebDriver) dentro do próprio sistema; coleta marca, modelo e preço de anúncios Webmotors e notifica o notification-service ao concluir ou falhar.
- **Integração**: Comunicação com auth-service e notification-service (microsserviços externos).

## Requisitos

- Ruby 3.3+
- Rails 8.1+
- PostgreSQL
- Redis (para Sidekiq)
- Selenium WebDriver, Nokogiri, Sidekiq, Faraday
- Chrome ou Chromium instalado
- Variáveis de ambiente para URLs dos microsserviços (ver abaixo)

## Instalação e configuração

```bash
bundle install
bin/rails db:create db:migrate
```

Para processar as tarefas de scraping em background, rode o Sidekiq em outro terminal:

```bash
bundle exec sidekiq
```

### Variáveis de ambiente

| Variável | Descrição | Default (local) |
|----------|------------|------------------|
| `DB_HOST` | Host do PostgreSQL | localhost |
| `DB_USERNAME` | Usuário PostgreSQL | postgres |
| `DB_PASSWORD` | Senha PostgreSQL | (vazio) |
| `REDIS_URL` | URL do Redis (Sidekiq) | redis://localhost:6379/0 |
| `AUTH_SERVICE_URL` | URL do microsserviço de autenticação | http://localhost:3001 |
| `NOTIFICATION_SERVICE_URL` | URL do microsserviço de notificações | http://localhost:3002 |

**URL do anúncio Webmotors:** use a URL normal da página do carro, por exemplo:  
`https://www.webmotors.com.br/comprar/bmw/x2/20-16v-turbo-activeflex-sdrive20i-gp-steptronic/4-portas/2018-2019/65919463`  
O sistema **abre essa URL no browser** (Selenium WebDriver + Chrome), deixa o JavaScript rodar e depois extrai marca, modelo e preço do HTML com Nokogiri (JSON-LD e seletores).

**Sites dinâmicos (Webmotors etc.):** os dados são renderizados por JavaScript. O sistema usa **Selenium WebDriver** para abrir a URL no Chrome em modo headless, esperar o carregamento e extrair do DOM com Nokogiri.

**Docker:** o `Dockerfile.dev` instala Chromium e cria symlink `google-chrome`. O browser roda em modo headless por padrão.

## Executando com Docker Compose

O `docker-compose.yml` fica neste repositório (pasta **webscraping-manager**). Coloque um `.env` nesta pasta (copie de `.env.example` da raiz do monorepo se precisar) e suba os serviços a partir daqui:

```bash
docker compose up --build
```

- **Sistema principal**: http://localhost:3000  
- **Auth API**: http://localhost:3001  
- **Notification API**: http://localhost:3002  

## Endpoints (uso interno / fluxo da aplicação)

A aplicação é server-rendered (HTML). Principais rotas:

| Método | Rota | Descrição |
|--------|------|------------|
| GET | / | Redireciona para login ou lista de tarefas |
| GET | /login | Formulário de login |
| POST | /login | Autenticação |
| DELETE | /logout | Encerrar sessão |
| GET | /register | Formulário de registro |
| POST | /register | Criar conta |
| GET | /tasks | Listar tarefas (protegido) |
| GET | /tasks/new | Formulário nova tarefa (protegido) |
| POST | /tasks | Criar tarefa (protegido) |
| GET | /tasks/:id | Detalhes da tarefa (protegido) |
| DELETE | /tasks/:id | Excluir tarefa (protegido) |

## Estrutura da tarefa

- Título/descrição (opcional)
- Status: `pendente`, `processando`, `concluída`, `falha`
- URL do anúncio (Webmotors)
- Resultado da coleta: marca, modelo, preço (quando concluída)
- Mensagem de erro (quando falha)
- Timestamps (criação, atualização, conclusão)
- Usuário que criou (user_id, user_email)

## Diagrama de arquitetura (resumo)

```
[Browser] <-> [Webscraping Manager :3000]  (UI + Tarefas + Scraping)
                    |                              |
                    |                              +-> Sidekiq (ScrapingJob + WebmotorsScraper)
                    |                                        |
                    +-> Auth Service :3001 (login/register/JWT)   +-> Notification Service (task_completed / task_failed)
                    +-> Notification Service :3002 (eventos task_created/completed/failed)

[PostgreSQL] (3 DBs: auth_service, notification_service, webscraping_manager)
[Redis] (Sidekiq)
```

## Testes

```bash
# Se RSpec estiver configurado
bundle exec rspec
```

---

Para subir apenas este projeto em desenvolvimento (com os outros serviços rodando separadamente), use as variáveis de ambiente acima e `bin/rails server`.
