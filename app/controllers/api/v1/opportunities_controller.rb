class Api::V1::OpportunitiesController < ApplicationController
  before_filter :get_company_params, only: [:create, :update]
  before_filter :get_contact_params, only: [:create, :update]
  before_filter :get_owner_params, only: [:create, :update]

  def index
    @opportunities = Opportunity.all
    render json: @opportunities
  end

  def create
    opportunity = Opportunity.new(params[:opportunity])
    set_opportunity(opportunity)
  end

  def update
    opportunity = Opportunity.find(params[:id])
    
    if opportunity
      opportunity.update_attributes(params[:opportunity])
      set_opportunity(opportunity)
    else
      render json: {error: 'it does not exist an opportunity'}
    end
  end

  def destroy
    opportunity = Opportunity.find(params[:id])
    if opportunity.nil?
      render json: {error: 'There is no an opportunity'}
    else
      opportunity.destroy
      render json: nil, status: :ok
    end
  end

  private

  def set_opportunity(opportunity)
    opportunity.company = @company unless @company.nil?
    opportunity.contact = @contact unless @contact.nil?
    opportunity.person = @owner

    if opportunity.save
      render json: opportunity, root: false
    else
      render json: {error: opportunity.errors}
    end
  end

  def get_company_params
    unless params[:opportunity].nil?
      company_name = params[:opportunity].delete(:company_name)
      company_id = params[:opportunity].delete(:company_id)

      if !company_id.nil?
        @company = Company.find(company_id)

      elsif !company_name.nil?
        @company = Company.where("name ILIKE ?", company_name).first || Company.create(name: company_name)
      end
    end
  end

  def get_contact_params
    unless params[:opportunity].nil?
      contact_params = params[:opportunity].delete(:contact)

      unless contact_params.nil?
        if !contact_params[:email].nil?
          contact_email = Contact.where(email: contact_params[:email]).first
          if contact_email.nil?
            @contact = Contact.create(contact_params)
          else
            @contact = contact_email

            if !@contact.company.nil? and @company.nil?
              @company = @contact.company
            end
          end
        else
          @contact = Contact.create(contact_params)
        end

        if !@company.nil? and @contact.company.nil?
          @contact.company = @company
          @contact.save
        end
      end
    end
  end

  def get_owner_params
    @owner = current_user.person

    if !params[:opportunity].nil?
      person_id = params[:opportunity].delete(:person_id)

      if !person_id.nil?
        @owner = Person.find(person_id) || current_user.person
      end
    end
  end
end
