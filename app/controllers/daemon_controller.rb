class DaemonController < ApplicationController
  skip_before_filter :authenticate_user!

  OK_STATUS   = 'ALIVE'
  BAD_STATUS  = 'DEAD'
  SALT         = 'NJHYdsfk32sd73#$2'

  def status
    status_text = DaemonStatus.instance.alive? ? "#{OK_STATUS}-#{SALT}" : "#{BAD_STATUS}-#{SALT}"
    render text: status_text
  rescue
    render text: "#{BAD_STATUS}-#{SALT}"
  end

end
