# README


## Getting Started

### 1. Start the PostgreSQL Database

Ensure your PostgreSQL database is running using Docker Compose:

```bash
docker-compose up -d db
```

### 2. Create and Migrate the Database

Run the following commands to create your databases and apply migrations:

```bash
docker run --rm --network spark_clinic_default -e DATABASE_URL=postgresql://postgres:password@db/spark_clinic_development -e SECRET_KEY_BASE=a_dummy_secret_key_for_demo_purposes spark_clinic bundle exec rails db:create db:migrate
```

### 3. Start the Rails Server

Once the database is set up, you can start the Rails server:

```bash
docker run -p 3000:3000 --rm --network spark_clinic_default -e DATABASE_URL=postgresql://postgres:password@db/spark_clinic_development -e SECRET_KEY_BASE=a_dummy_secret_key_for_demo_purposes spark_clinic bundle exec rails server -b 0.0.0.0
```

Your application should then be accessible at `http://localhost:3000`.