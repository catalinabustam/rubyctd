require 'sinatra'
require 'slim'
require 'data_mapper'
require 'dicom'
include DICOM

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")


class Patient
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String, :required => true
  property :completed_at, DateTime

  has n, :ctdregs
end

class Ctdreg
  include DataMapper::Resource
  property :id, Serial

  belongs_to :patient 
end
DataMapper.finalize

get '/' do
  @task = Task.all
  slim :task
end

post '/' do
  @task =  params[:task]
  slim :task
end

def dicomclient
	node = DClient.new("192.168.3.3", 11112, ae: 'PACSCDR')
	date=datef
	find_studies("0008,0020" => datef, "0008,0061" => 'CT')
	

end

def datef(date)
	y=date.year
	m=sprintf '%02d',date.month
	d=sprintf '%02d', date.day
	y.to_s+m.to_s+d.to_s  
end