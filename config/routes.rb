city_constraint = Proc.new do |req|
  city = req.params[:city]
  city.blank? || city.match(/^(#{AlumniClient.new.city_slugs.join("|")})$/i)
end

Rails.application.routes.draw do

  # config/static_routes.yml
  STATIC_ROUTES.each do |template, locale_paths|
    locale_paths.each do |locale, page|
      get page => "pages##{template}", template: template, locale: locale.to_sym, as: "#{template}_#{locale}".to_sym
    end
  end

  # Redirects
  get 'premiere', to: redirect('programme')
  get 'marseille', to: redirect('aix-marseille')
  get 'en', to: redirect('/')
  get 'en/*path', to: redirect { |path_params, req| path_params[:path] }
  get 'en/blog/*path', to: redirect { |path_params, req| "blog/#{path_params[:path]}" }
  get 'fr/blog/*path', to: redirect { |path_params, req| "blog/#{path_params[:path]}" }

  get 'ondemand/*path', to: redirect { |path_params, req| "https://ondemand.lewagon.org/#{req.fullpath.gsub("/ondemand/", "")}" }
  get 'codingstationparis', to: redirect('https://www.meetup.com/fr-FR/Le-Wagon-Paris-Coding-Station')


  constraints(city_constraint) do
    get "apply/(:city)" => "applies#new", locale: :en, as: :apply_en
    get "postuler/(:city)" => "applies#new", locale: :fr, as: :apply_fr
  end

  resource :apply, only: %s(create)
  scope "(:locale)", locale: /fr/ do
    root to: "pages#home"
    get "faq", to: "pages#show", template: "faq", as: :faq
    get "jobs", to: "pages#show", template: "jobs", as: :jobs
    get "stack", to: "pages#stack", template: "stack", as: :stack
    get "tv", to: "pages#tv", template: "tv", as: :tv
    get "alumni" => "students#index", as: :alumni
    constraints(city_constraint) do
      get ":city" => "cities#show", as: :city
    end
    resources :projects, only: [:show]
    resources :stories, only: [:index, :show]
    resources :students, only: [:show]
  end

  get "blog", to: 'posts#index'
  get "blog/rss", to: 'posts#rss', defaults: { format: :xml }
  get "blog/:slug", to: 'posts#show'

  resources :subscribes, only: :create

  # API
  resource :cache, only: :destroy

  # SEO
  get 'robots', to: 'pages#robots'

  # Old
  get 'wagon_bar', to: redirect('/fr')
end

# Create helper for static_routes
Rails.application.routes.url_helpers.module_eval do
  STATIC_ROUTES.each do |route, _|
    define_method "#{route}_path".to_sym do |args = {}|
      locale = args[:locale] || :fr
      self.send(:"#{route}_#{locale}_path")
    end

    define_method "#{route}_url".to_sym do |args = {}|
      locale = args[:locale] || :fr
      self.send(:"#{route}_#{locale}_url")
    end
  end
end
