require 'sinatra'
require 'slim'
require 'data_mapper'
require 'dicom'
include DICOM

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

a=1+2
puts a


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
	node = DClient.new("192.168.3.3", 11112, host_ae: 'PACSCDR')
	date=datef(Date.today)
	studies=node.find_studies("0008,0020" => date, "0008,0061" => 'CT')

  studies.each do |stu|

    patid=patid=stu["0010,0020"]
    studydate=stu["0008,0020"]

    series=node.find_series("0020,000D" => stu["0020,000D"], "0008,0060"=>"CT")

      series.each do |ser|
        images=node.find_images("0020,000E"=> ser["0020,000E"])
        image=node.move_image('RUBY', "0008,0018"=> images[0]["0008,0018"])
        filename= "#{image[0]["0008,0018"]}.dcm"
        path="/Users/catalinabustamante/Desktop/dicom/image#{patid}/#{studydate}/#{filename}"
        dcm = DObject.read(path)
        Patient.id=dcm.value("0010,0020") 
        Patient.name=dcm.value("0010,0010") 
      end
  end
 

end

def dicomserver
  s = DServer.new(11113, :host_ae => "RUBY")
  s.start_scp("/Users/catalinabustamante/Desktop/dicom/image")
end


def datef(date)
	y=date.year
	m=sprintf '%02d',date.month
	d=sprintf '%02d', date.day
	y.to_s+m.to_s+d.to_s  
end