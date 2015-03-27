module LHEF

import Base.dot

using LightXML

immutable EventHeader
    nup::Uint8          # Number of particles
    ldprup::Uint8       # Process type?
    xwgtup::Float64     # Event Wight
    scalup::Float64     # Scale
    αem::Float64        # AQEDUP
    αs::Float64         # AQCDUP
end

immutable FourVector
    data::NTuple{4,Float64}
end
getindex(x::FourVector,i) = x.data[i+1]

# Mostly negative convention
dot(x::FourVector,y::FourVector) = (x[0]*y[0]-x[1]*y[1]-x[2]*y[2]-x[3]*y[3])

immutable Particle
    particle::Int8
    status::Int8
    mothup::NTuple{2,Uint8}
    color::NTuple{2,Uint16}
    pμ::FourVector
    m::Float64
    vtimup::Float64
    spinup::Float64
end

immutable Event
    header::EventHeader
    data::Vector{Particle}
end
 
function parse_lhe(filename; format = nothing)
    if format === nothing
        # Format not declared, inferring from extension
        fparts = split(basename(filename),".")
        if fparts[end] == "lhe"
            format = :lhe
        elseif fparts[end] == "gz" && fparts[end-1] == "lhe"
            format = :lhegz
        end
    end

    @assert format == :lhe
    lhefile = parse_file(filename)
    lhenode = root(lhefile)

    (name(lhenode) == "LesHouchesEvents") || error("Invalid root node")
    (attributes_dict(lhenode)["version"] == "3.0") || error("Unsupported Version")

    events = get_elements_by_tagname(lhenode,"event")

    [begin
        data = content(event)
        lines = split(data,'\n',keep=false)
        headerdata = split(lines[1],' ',keep=false)
        header = EventHeader(parseint(headerdata[1]), parseint(headerdata[2]),
            parsefloat(Float64, headerdata[3]), parsefloat(Float64, headerdata[4]),
            parsefloat(Float64, headerdata[5]), parsefloat(Float64, headerdata[6]))
        data = [begin
            fields = split(line,' ',keep=false)
            p = Particle(parseint(Int8,fields[1]),parseint(Int8,fields[2]),
                (parseint(Uint8,fields[3]),parseint(Uint8,fields[4])),
                (parseint(Uint16,fields[5]),parseint(Uint16,fields[6])),
                FourVector((parsefloat(Float64,fields[10]),parsefloat(Float64,fields[7]),
                    parsefloat(Float64,fields[8]),parsefloat(Float64,fields[9]))),
                parsefloat(Float64, fields[11]), parsefloat(Float64, fields[12]),
                parsefloat(Float64, fields[13]))
            p
        end for line in lines[2:end]]
        Event(header,data)
    end for event in events]
end

# package code goes here

end # module
