require 'kindlefodder'
require 'uri'

class ZOJ < Kindlefodder

  def httpget url
    puts "GET #{url}"
    sleep 3
    `curl -s -L "#{url}"`
  end

  def get_source_files
    start_url = 'http://acm.zju.edu.cn/onlinejudge/showProblemsets.do'
    @start_doc = Nokogiri::HTML httpget(start_url)
    
    File.open( "#{output_dir}/sections.yml", 'w' ) {|f|
      f.puts extract_volumes.to_yaml
    }
  end

  def document
    {
      'title' => 'Zhejiang University Online Judge',
      'cover' => nil,
      'masthead' => nil,
    }
  end

  def extract_volumes
    vols = @start_doc.css( "td#content div#content_body form a" ).select{ |a|
      a.inner_text.match( /Vol \d+/ )
    }

    FileUtils::mkdir_p "#{output_dir}/articles"
    xs = []

    vols.each do |vol|
      xs <<  {
        title:    "Volume #{vol.inner_text[/\d+/]}",
        articles: extract_problems("http://acm.zju.edu.cn#{vol[:href]}")
      }
    end
    xs
  end

  def problem_head title
'<html>
  <head>
    <meta http-equiv=Content-Language content=UTF-8 />
    <style type="text/css">
      .bigProblemTitle
      {
      font-size: 200%;
      color:     blue;
      text-align:center
      }

      #content_title
      {
      background-color: eeeeee;
      font-size: 120%;
      font-weight: bold;
      float: left;
      clear: left;
      width: 100%;
      }
    </style>
  </head>
  <body>
  '
  end

  def problem_tail
    '</body></html>'
  end

  def extract_problems url
    vol_html = httpget url
    vol_doc  = Nokogiri::HTML vol_html
    
    problems = vol_doc.css( "td#content div#content_body table.list tr" ).select do |tr|
      tr[:class].match( /^row(Odd|Even)/ )
    end

    xs = []
    problems.each do |problem|
      td_id    = problem.css( "td.problemId" )[0]
      td_title = problem.css( "td.problemTitle" )[0]
      id    = td_id.inner_text
      title = td_title.inner_text
      href  = td_title.inner_html[/href="(.*?)"/,1]
      path  = "articles/#{id}.html"

      File.open( "#{output_dir}/#{path}", 'w') do |f|
        f.puts problem_body href,title
      end

      xs << {
        title: title,
        path:  path,
        description: '',
        autho: ''
      }
    end
    xs
  end

  def problem_body href,title
    @baseurl = "http://acm.zju.edu.cn/onlinejudge/"
    html = httpget "http://acm.zju.edu.cn#{href}"
    doc  = Nokogiri::HTML html
    main = doc.css( "table#main td#content" )[0]
    main.search( "img[@src]" ).each {|img|
      img['src'] = @baseurl + URI.unescape(img['src'])
      ## problem 3377 hack
      img['src'] = img['src'].sub( /\/$/, '' )
    }
    
    problem_head(title) + main.inner_html + problem_tail
  end

end

ZOJ.generate
