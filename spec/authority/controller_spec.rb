require 'spec_helper'
require 'support/ability_model'
require 'support/example_controller'
require 'support/user'

describe Authority::Controller do

  describe "when including" do
    it "should specify rescuing security transgressions" do
      class DummyController < ExampleController ; end
      DummyController.should_receive(:rescue_from).with(Authority::SecurityTransgression, :with => 'forbidden')
      DummyController.send(:include, Authority::Controller)
    end
  end

  describe "after including" do
    before :all do
      ExampleController.send(:include, Authority::Controller)
    end

    describe "DSL (class) methods" do
      it "should allow specifying the model to protect" do
        ExampleController.check_authorization_on AbilityModel
        ExampleController.authority_resource.should eq(AbilityModel)
      end

      it "should pass the options provided to the before filter that is set up" do
        @options = {:only => [:show, :edit, :update]}
        ExampleController.should_receive(:before_filter).with(:run_authorization_check, @options)
        ExampleController.check_authorization_on AbilityModel, @options
      end

      it "should give the controller its own copy of the authority actions map" do
        ExampleController.check_authorization_on AbilityModel
        ExampleController.authority_actions.should be_a(Hash)
        ExampleController.authority_actions.should_not be(Authority.configuration.authority_actions)
      end

      it "should allow specifying the authority action map in the `check_authorization_on` declaration" do
        ExampleController.check_authorization_on AbilityModel, :actions => {:eat => 'delete'}
        ExampleController.authority_actions[:eat].should eq('delete')
      end

      it "should have a write into the authority actions map usuable in a DSL format" do
        ExampleController.authority_action :smite => 'delete'
        ExampleController.authority_actions[:smite].should eq('delete')
      end
    end

    describe "instance methods" do
      before :each do 
        @user       = User.new
        @controller = ExampleController.new
        @controller.stub!(:action_name).and_return(:index)
        @controller.stub!(Authority.configuration.user_method).and_return(@user)
      end

      it "should check authorization on the model specified" do
        @controller.should_receive(:check_authorization_for).with(:index, AbilityModel, @user)
        @controller.send(:run_authorization_check)
      end

      it "should raise a SecurityTransgression if authorization fails" do
        expect { @controller.send(:run_authorization_check) }.to raise_error(Authority::SecurityTransgression)
      end

      it "should raise a MissingAuthorityAction if there is no corresponding action for the controller"

      describe "forbidden action" do
        it "should log an error"
        it "should render the public/403.html file"
      end
    end
  end

end

