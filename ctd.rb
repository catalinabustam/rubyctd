require 'data_mapper'
require 'dicom'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-sqlite-adapter'
include DICOM

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")


class Patient
  include DataMapper::Resource
  property :id,           Serial
  property :patname,      String, :required => true
  property :patid,        String
  property :patbd,        String
  property :patsex,       String

  has n, :ctdregs
end


class Ctdreg
  include DataMapper::Resource
  property :id, Serial
  property :accnumber, String
  property :sopclassui, String
  property :studyname, String
  property :reqproce, String
  property :opname, String
  property :studydate, String
  property :seriesdesc, String
  property :protocolname, String
  property :comments, String
  property :patage, String
  property :patweigth,  String
  property :voltage, String
  property :current, String
  property :revtime, String
  property :expotime, String
  property :expomas, String
  property :coliwidth, String
  property :ctdivol, String
  property :ctdiphan, String
  property :collediame, String
  property :spiralpitch, String
  property :tablefeedpr, String
  property :exposuremodu, String
  property :scanlength, String

  belongs_to :patient 
end

DataMapper.auto_upgrade!



def dicomclient
	node = DClient.new("192.168.3.3", 11112, host_ae: 'PACSCDR')
	date=datef(Date.today)
	studies=node.find_studies("0008,0020" => date, "0008,0061" => 'CT')

  studies.each do |stu|

    patid=stu["0010,0020"]
    studydate=stu["0008,0020"]

    series=node.find_series("0020,000D" => stu["0020,000D"], "0008,0060"=>"CT")

      series.each do |ser|
        images=node.find_images("0020,000E"=> ser["0020,000E"])
        puts images
        puts images[0]
        image=node.move_image('RUBY', "0008,0018"=> images[0]["0008,0018"])
        filename= "#{images[0]["0008,0018"]}.dcm"
        path="/Users/catalinabustamante/Desktop/dicom/image#{patid}/#{studydate}/CT/#{filename}"
        fsize=File.size("#{path}")/(1024*1024)

         if fsize!=0
            dcm = DObject.read(path)
            patage=age(dcm.value("0010,0030"), dcm.value("0008,0020"))
            patient=Patient.first_or_create({:patid => patid}, {:patname =>dcm.value("0008,1030"), :patid => dcm.value("0010,0020"), :patbd => dcm.value("0010,0030"), :patsex => dcm.value("0010,0040")})
            ctd=patient.ctdregs.create(:accnumber => dcm.value("0008,0050") , :sopclassui => dcm.value("0008,0018"), :studyname => dcm.value("0008,1030"), :reqproce => dcm.value("0032,1060"), :opname => dcm.value("0008,1070"), :studydate => dcm.value("0008,0020"), :seriesdesc => dcm.value("0008,103e"), :protocolname => dcm.value("0018,1030"), :comments => dcm.value("0020,4000"), :patage =>patage, :patweigth => dcm.value("0010,1030"), :voltage => dcm.value("0018,0060"), :current => dcm.value("0008,9330"), :revtime => dcm.value("0018,9305"), :expotime => dcm.value("0018,9328"), :expomas => dcm.value("0018,9332"), :coliwidth => dcm.value("0018,9307"),:ctdivol => dcm.value("0018,9345"), :ctdiphan => dcm.value("0018,9323"), :collediame => dcm.value("0018,0090"), :spiralpitch => dcm.value("0018,9311"), :tablefeedpr => dcm.value("0018,9311"), :exposuremodu => dcm.value("0018,9323"), :scanlength => dcm.value("0018,1302"))
            

          end
      end
  end
 

end
 
DataMapper.finalize

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

def age(bday, studydate)
  bdate=Date.strptime("{ #{bday[0,4].to_i}, #{bday[4,2].to_i}, #{bday[6,2].to_i} }", "{ %Y, %m, %d }")
  studate=Date.strptime("{ #{studydate[0,4].to_i}, #{studydate[4,2].to_i}, #{studydate[6,2].to_i} }", "{ %Y, %m, %d }")
  age= (studate- bdate).to_f / 365
  '%.2f' % age
end

dicomclient