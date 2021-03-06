class ApplicationController < ActionController::Base
  include ApplicationHelper, ApplicationConcern

  NOT_FOUND_ERROR_CLASSES = [
    ActionController::UrlGenerationError,
    ActiveRecord::RecordNotFound,
    ActionView::MissingTemplate
  ].freeze

  before_action :check_for_maintenance
  protect_from_forgery with: :exception

  def initialize
    super
    @display_help = true
  end

  def after_sign_in_path_for(resource)
    if projet_id = session[:projet_id_from_opal]
      projet_or_dossier_path(Projet.find_by_id(projet_id))
    else
      if resource.is_a?(User)
        resource.projets.first.update(:max_registration_step => Projet::STEP_MISE_EN_RELATION)
      end
      stored_location_for(resource) || root_path
    end
  end

  def check_for_maintenance
    if ENV["WEBSITE_MAINTENANCE"] == "true" && params[:action] != "maintenance"
      return render :maintenance
    end
  end

  def current_ability
    if current_agent
      @current_ability ||= Ability.new(current_agent, :agent, @projet_courant)
    else
      @current_ability ||= Ability.new(current_user, :user, @projet_courant)
    end
  end

  def debug_exception
    raise "Exception de test"
  end

  def error_not_found
	render "errors/not_found"
  end

  rescue_from Exception, with: :render_error

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      if current_user && @projet_courant.present?
        if @projet_courant.locked_at.nil?
          format.html { redirect_to projet_demandeur_path(@projet_courant), alert: exception.message }
        elsif @projet_courant.demandeur_user.blank?
          format.html { redirect_to projet_eligibility_path(@projet_courant), alert: exception.message }
        elsif @projet_courant.invitations.blank?
          format.html { redirect_to projet_mise_en_relation_path(@projet_courant), alert: exception.message }
        else
          format.html { redirect_to root_path, alert: exception.message }
        end
      elsif @projet_courant.present? && @projet_courant.demandeur_user.present?
        format.html { redirect_to new_user_session_path, alert: "veuillez vous connecter pour continuer" }
      elsif @projet_courant.present? && @projet_courant.demande.present?
        format.html { redirect_to new_user_registration_path, alert: "veuillez vous inscrire pour continuer" }
      else
        format.html { redirect_to root_path, alert: exception.message }
      end
    end
  end

  def maintenance
  end

  private

  def render_error(exception)
    raise exception unless Rails.env.production?
    if NOT_FOUND_ERROR_CLASSES.include? exception.class
      render "errors/not_found"
    else
      send_error_notifications(exception) rescue nil
      render "errors/internal_server_error"
    end
  end

  def send_error_notifications(exception)
    server_name      = request.env["SERVER_NAME"]
    method           = request.method
    url              = request.url
    parameters       = filtered_request_parameters
    ip               = request.ip
    responsible_type = current_agent ? "Agent" : "User"
    responsible_id   = current_agent.try(:id) || current_user.try(:id)
    error_message    = exception.message.to_s
    backtrace        = exception.backtrace[0..4].join("\n")

    SlackNotifyJob.perform_later(server_name, method, url, parameters, ip, responsible_type, responsible_id, error_message, backtrace)
  end

  def filtered_request_parameters
    request_paramters = request.parameters.deep_dup

    Rails.application.config.filter_parameters.each do |filter_parameter|
      request_paramters.deep_reject! filter_parameter
    end

    request_paramters
  end
end

