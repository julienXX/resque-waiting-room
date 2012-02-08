Usage
------

	class InvitationJob < Resque::Plugins::WaitingRoomJob
	  can_be_performed :times => 600, :period => 3600       # 600 performs per hour

	  #rest of your class here
	end


