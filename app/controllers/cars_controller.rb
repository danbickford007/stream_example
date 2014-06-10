class CarsController < ApplicationController
  before_action :set_car, only: [:show, :edit, :update, :destroy]

  include ActionController::Live
  Mime::Type.register "text/event-stream", :stream

  def index
    # response.headers['Content-Type'] = 'text/event-stream'
  end

  def send_message
    response.headers['Content-Type'] = 'text/event-stream'
    response.stream.write params[:message]
    response.stream.close
  end

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    time = DateTime.now - 5.seconds
    begin
      redis = Redis.new
      redis.subscribe('messages.create') do |on|
        on.message do |event, data|
          response.stream.write "data: #{data}\n\n"
        end
      end
    rescue => e
      p '!!!!!!!!!!!!!!'
      p e
      p e.backtrace 
    ensure
      p '!!!!!!!!!!!!!!-closing'
      response.stream.close
    end
  end

  def show
  end

  # GET /cars/new
  def new
    @car = Car.new
  end

  # GET /cars/1/edit
  def edit
  end

  # POST /cars
  # POST /cars.json
  def create
    @car = Car.new(car_params)
    @car.save
    $redis.publish('messages.create', @car.make)
    respond_to do |format|
      format.js { render js: "" } 
    end
  end

  # PATCH/PUT /cars/1
  # PATCH/PUT /cars/1.json
  def update
    respond_to do |format|
      if @car.update(car_params)
        format.html { redirect_to @car, notice: 'Car was successfully updated.' }
        format.json { render :show, status: :ok, location: @car }
      else
        format.html { render :edit }
        format.json { render json: @car.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cars/1
  # DELETE /cars/1.json
  def destroy
    @car.destroy
    respond_to do |format|
      format.html { redirect_to cars_url, notice: 'Car was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_car
      @car = Car.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def car_params
      params.require(:car).permit(:make, :model)
    end
end
