require_relative 'test_helper'

TEST_DATA_DIRECTORY = 'test/test_data'

describe "TripDispatcher class" do
  def build_test_dispatcher
    return RideShare::TripDispatcher.new(
      directory: TEST_DATA_DIRECTORY
    )
  end

  describe "Initializer" do
    it "is an instance of TripDispatcher" do
      dispatcher = build_test_dispatcher
      expect(dispatcher).must_be_kind_of RideShare::TripDispatcher
    end

    it "establishes the base data structures when instantiated" do
      dispatcher = build_test_dispatcher
      [:trips, :passengers].each do |prop|
        expect(dispatcher).must_respond_to prop
      end

      expect(dispatcher.trips).must_be_kind_of Array
      expect(dispatcher.passengers).must_be_kind_of Array
      # expect(dispatcher.drivers).must_be_kind_of Array
    end

    it "loads the development data by default" do
      # Count lines in the file, subtract 1 for headers
      trip_count = %x{wc -l 'support/trips.csv'}.split(' ').first.to_i - 1

      dispatcher = RideShare::TripDispatcher.new

      expect(dispatcher.trips.length).must_equal trip_count
    end
  end

  describe "passengers" do
    describe "find_passenger method" do
      before do
        @dispatcher = build_test_dispatcher
      end

      it "throws an argument error for a bad ID" do
        expect{ @dispatcher.find_passenger(0) }.must_raise ArgumentError
      end

      it "finds a passenger instance" do
        passenger = @dispatcher.find_passenger(2)
        expect(passenger).must_be_kind_of RideShare::Passenger
      end
    end

    describe "Passenger & Trip loader methods" do
      before do
        @dispatcher = build_test_dispatcher
      end

      it "accurately loads passenger information into passengers array" do
        first_passenger = @dispatcher.passengers.first
        last_passenger = @dispatcher.passengers.last

        expect(first_passenger.name).must_equal "Passenger 1"
        expect(first_passenger.id).must_equal 1
        expect(last_passenger.name).must_equal "Passenger 8"
        expect(last_passenger.id).must_equal 8
      end

      it "connects trips and passengers" do
        dispatcher = build_test_dispatcher
        dispatcher.trips.each do |trip|
          expect(trip.passenger).wont_be_nil
          expect(trip.passenger.id).must_equal trip.passenger_id
          expect(trip.passenger.trips).must_include trip
        end
      end
    end
  end

  # TODO: un-skip for Wave 2
  describe "drivers" do
    describe "find_driver method" do
      before do
        @dispatcher = build_test_dispatcher
      end

      it "throws an argument error for a bad ID" do
        expect { @dispatcher.find_driver(0) }.must_raise ArgumentError
      end

      it "finds a driver instance" do
        driver = @dispatcher.find_driver(2)
        expect(driver).must_be_kind_of RideShare::Driver
      end
    end

    describe "Driver & Trip loader methods" do
      before do
        @dispatcher = build_test_dispatcher
      end

      it "accurately loads driver information into drivers array" do
        first_driver = @dispatcher.drivers.first
        last_driver = @dispatcher.drivers.last

        expect(first_driver.name).must_equal "Driver 1 (unavailable)"
        expect(first_driver.id).must_equal 1
        expect(first_driver.status).must_equal :UNAVAILABLE
        expect(last_driver.name).must_equal "Driver 3 (no trips)"
        expect(last_driver.id).must_equal 3
        expect(last_driver.status).must_equal :AVAILABLE
      end

      it "connects trips and drivers" do
        dispatcher = build_test_dispatcher
        dispatcher.trips.each do |trip|
          expect(trip.driver).wont_be_nil
          expect(trip.driver.id).must_equal trip.driver_id
          expect(trip.driver.trips).must_include trip
        end
      end
    end
  end

  describe "request_trip method" do
    it "creates an instance of Trip" do
      dispatcher = build_test_dispatcher
      new_length = dispatcher.trips.length + 1

      dispatcher.request_trip(1)

      expect(dispatcher.trips.length).must_equal new_length
      expect(dispatcher.trips.last).must_be_instance_of RideShare::Trip
    end

    it "will return first available driver" do
      dispatcher = build_test_dispatcher
      
      dispatcher.request_trip(1)
      #find the passenger id 1 and then see if the driver id is 2
      expect(dispatcher.trips.last.driver_id).must_equal 3
    end

    it "will change driver's status to unavailable" do
      dispatcher = build_test_dispatcher

      dispatcher.request_trip(1)

      expect(dispatcher.find_driver(3).status).must_equal :UNAVAILABLE
    end

    it "will have a cost, rating, and end time of nil for new trip" do
      dispatcher = build_test_dispatcher
      
      dispatcher.request_trip(1)

      expect(dispatcher.trips.last.end_time).must_be_nil
      expect(dispatcher.trips.last.cost).must_be_nil
      expect(dispatcher.trips.last.rating).must_be_nil
    end
    it "update driver's trips" do 
      dispatcher = build_test_dispatcher
      new_length = dispatcher.find_driver(3).trips.length + 1

      dispatcher.request_trip(1)
      expect(dispatcher.find_driver(3).trips.length).must_equal new_length
    end 

    it "update passenger's trips" do 
      dispatcher = build_test_dispatcher
      dispatcher.request_trip(1)
      expect(dispatcher.find_passenger(1).trips.length).must_equal 2
    end 
    it "raise error when there is no available driver" do 
      dispatcher = build_test_dispatcher
      dispatcher.drivers.map {|driver|driver.change_status}
      expect{dispatcher.request_trip(1)}.must_raise ArgumentError
    end 

    it "selects an available driver" do
      dispatcher = build_test_dispatcher
      dispatcher.request_trip(1)
      expect(dispatcher.trips.last.driver_id).wont_equal 1
    end

    it "selects driver with no trips first" do
      dispatcher = build_test_dispatcher
      dispatcher.request_trip(1)
      expect(dispatcher.trips.last.driver_id).must_equal 3
    end
  end
end
