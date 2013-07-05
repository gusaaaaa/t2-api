class Api::V1::ProjectsController < ApplicationController
  # GET /projects.json
  def index
    render json: Project.all
  end

  # GET /projects/1.json
  def show
    project = Project.find(params[:id])
    render json: project
  end

  # POST /projects.json
  def create
    project = Project.new(params[:project])
    if project.save
      render json: project, status: :created
    else
      render json: project.errors, status: :unprocessable_entity
    end
  end

  # PUT /projects/1.json
  def update
    project = Project.find(params[:id])
    if project.update_attributes(params[:project])
      render json: project, status: :ok
    else
      render json: project.errors, status: :unprocessable_entity
    end
  end

  # DELETE /projects/1.json
  def destroy
    project = Project.find(params[:id])
    project.destroy
    render json: nil, status: :ok
  end
end
