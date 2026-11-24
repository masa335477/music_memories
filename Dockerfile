FROM ruby:3.4.13
WORKDIR /app

# PostgreSQL接続に必要なライブラリ
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      postgresql-client \
      chromium \
      chromium-driver && \
    rm -rf /var/lib/apt/lists/*

# Gemのインストール
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Railsアプリのコピー
COPY . .

# 本番用のCSSとJavaScriptをビルド時に生成
RUN RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile

# Renderとローカルで使用するポート
EXPOSE 3000

# Railsの起動
CMD ["sh", "-c", "bin/rails db:prepare && exec bin/rails server -b 0.0.0.0 -p ${PORT:-3000}"]