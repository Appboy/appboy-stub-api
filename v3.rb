# Encoding: utf-8
require 'sinatra/base'
require 'sinatra/cross_origin'
require 'multi_json'
require 'newrelic_rpm'
require 'active_support/hash_with_indifferent_access'

class StubApi < Sinatra::Base
  register Sinatra::CrossOrigin

  configure do
    enable :cross_origin
    enable :logging
  end

  options '*' do
    response.headers["Allow"] = "HEAD,GET,PUT,DELETE,OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"

    status 200
  end

  error do
    'An error occured: ' + request.env['sinatra.error'].message
  end

  def verify_device(device, name = "")
    logger.info("Received #{name} device with model '#{device[:model]}', os_version '#{device[:os_version]}', carrier '#{device[:carrier]}', resolution '#{device[:resolution]}', locale '#{device[:locale]}', time_zone '#{device[:time_zone]}'.  Also these various sometimes params: ios_idfv '#{device[:ios_idfv]}', ios_idfa '#{device[:ios_idfa]}', google_ad_id '#{device[:google_ad_id]}', browser '#{device[:browser]}'")
  end

  def halt_with_error(error, response_body)
    logger.error(error)
    response_body[:error] = error
    halt response_body.to_json
  end

  get '/test' do
    "the stub api is up!"
  end

  post '/v3/data/' do
    response_body = {}
    params = MultiJson.decode(request.body.read)
    params = HashWithIndifferentAccess.new(params)

    puts request.body.read
    puts params

    if params[:time].nil?
      halt_with_error("time must not be nil", response_body)
    end
    if params[:sdk_version].nil?
      halt_with_error("sdk_version must not be nil", response_body)
    end
    if params[:device_id].nil?
      halt_with_error("device_id must not be nil", response_body)
    end

    logger.info("Received data with timestamp #{Time.at(params[:time])}, sdk_version #{params[:sdk_version]}, app_version #{params[:app_version]}, device_id #{params[:device_id]}")

    if !params[:device].nil?
      verify_device(params[:device])
    end

    if !params[:events].nil?
      logger.info("Received #{params[:events].length} events")
      params[:events].each do |event_object|
        if event_object[:name].nil?
          halt_with_error("event name must not be nil", response_body)
        end

        allowed_events = {
          "ce" => "CustomEvent",
          "p" => "InAppPurchase",
          "pc" => "PushNotificationTrackEvent",
          "ca" => "IosPushCategoryActionEvent",
          "i" => "InternalEvent",
          "ie" => "InternalErrorEvent",
          "ci" => "CardImpressionEvent",
          "cc" => "CardClickEvent",
          "ss" => "SessionStartEvent",
          "se" => "SessionEndEvent",
          "si" => "SlideUpImpressionEvent",
          "sc" => "SlideUpClickEvent",
          "sbc" => "SlideUpButtonClickEvent",
          "lr" => "LocationRead"
        }
        if !allowed_events.has_key?(event_object[:name])
          halt_with_error("received invalid event name #{event_object[:name]}", response_body)
        end

        if event_object[:time].nil?
          halt_with_error("event time must not be nil", response_body)
        end
        if event_object[:data].nil?
          halt_with_error("event data must not be nil", response_body)
        end

        logger.info("Received #{allowed_events[event_object[:name]]} event, with time #{event_object[:time]}, data #{event_object[:data].inspect}, session_id #{event_object[:session_id]}, user_id #{event_object[:user_id]}")
      end
    end

    if !params[:attributes].nil?
      params[:attributes].each do |attributes_object|
        logger.info("Received attributes for user #{attributes_object[:user_id]} with custom #{attributes_object[:custom].inspect}, push_token #{attributes_object[:push_token]}, first_name #{attributes_object[:first_name]}, last_name #{attributes_object[:last_name]}, email #{attributes_object[:email]}, dob #{attributes_object[:dob]}, country #{attributes_object[:country]}, home_city #{attributes_object[:home_city]}, bio #{attributes_object[:bio]}, gender #{attributes_object[:gender]}, phone #{attributes_object[:phone]}, email_subscribe #{attributes_object[:email_subscribe]}, push_subscribe #{attributes_object[:push_subscribe]}, image_url #{attributes_object[:image_url]}, facebook #{attributes_object[:facebook]}, twitter #{attributes_object[:twitter]}, foursquare #{attributes_object[:foursquare]}, foursquare_access_token #{attributes_object[:foursquare_access_token]}")
      end
    end

    if !params[:feedback].nil?
      params[:feedback].each do |feedback_object|
        if feedback_object[:message].nil?
          halt_with_error("feedback message must not be nil", response_body)
        end
        if feedback_object[:is_bug].nil?
          halt_with_error("feedback is_bug must not be nil", response_body)
        end
        if feedback_object[:reply_to].nil?
          halt_with_error("feedback reply_to must not be nil", response_body)
        end

        logger.info("Received feedback with message #{feedback_object[:message]}, is_bug #{feedback_object[:is_bug]}, reply_to #{feedback_object[:reply_to]}, user_id #{feedback_object[:user_id]}")

        if !feedback_object[:device].nil?
          verify_device(feedback_object[:device], "feedback")
        end
      end
    end

    if !params[:respond_with].nil?
      respond_with = params[:respond_with]

      if respond_with[:feed].to_s == "true"
        response_body[:feed] = [
          { # Cross Promotion Card Small
            "id"  => "crosspromosmall1",
            "viewed" => false,
            "type" => "cross_promotion_small",
            "title" => "Hair MakeOver - Home Edition",
            "subtitle" => "Lifestyle, Entertainment",
            "caption" => "Recommended",
            "image" => "http://www.image.com/foo.png",
            "rating" => 4.0,
            "reviews" => 10000,
            "price" => 0.25,
            "url" => "https://itunes.apple.com/foo",
            "media_type" => "ItunesSoftware",
            "itunes_id" => 560147174,
            "created" => (Time.now - 3.months).to_i,
            "updated" => (Time.now - 3.days).to_i,
            "categories" => ["news"],
            "expires_at" => (Time.now + 1.day).to_i,
            # Optional
            "display_price" => "£3.33",
            "universal" => true
          },
          { # Captioned image
            "id" => "captioned1",
            "viewed" => false,
            "type" => "captioned_image",
            "image" => "http://www.image.com/foo.jpg",
            "title" => "Jake's Bar",
            "description" => "Come to Jake's bar tonight for free food!",
            "created" => (Time.now - 2.months).to_i,
            "updated" => (Time.now - 2.days).to_i,
            "categories" => [],
            "expires_at" => (Time.now + 2.hours).to_i,
            # Optional
            "url" => "http://www.jakesbar.com",
            "domain" => "jakesbar.com",
            "aspect_ratio" => 1.33333
          },
          { # Text Announcement
            "id" => "text1",
            "viewed" => false,
            "type" => "text_announcement",
            "title" => "Plants vs. Zombies version 90.1",
            "description" => "Plants vs. Zombies fans, we're getting ready to release foo",
            "created" => (Time.now - 2.months).to_i,
            "updated" => (Time.now - 1.days).to_i,
            "categories" => [],
            "expires_at" => (Time.now + 2.hours).to_i,
            # Optional
            "url" => "http://tapbots.com/announcement",
            "domain" => "jakesbar.com"
          },
          { # News Item
            "id" => "news1",
            "viewed" => false,
            "type" => "short_news",
            "description" => "Thanks for supporting us!",
            "image" => "http://www.image.com/foo",
            "created" => (Time.now - 2.months).to_i,
            "updated" => (Time.now - 1.days).to_i,
            "categories" => [],
            "expires_at" => (Time.now + 2.hours).to_i,
            # Optional
            "title" => "Tapbots hits 1MM downloads!",
            "url" => "http://tapbots.com/announcement",
            "domain" => "tapbots.com"
          },
          { # Banner
            "id" => "banner1",
            "viewed" => false,
            "type" => "banner_image",
            "image" => "http://www.image.com/foo.png",
            "created" => (Time.now - 2.months).to_i,
            "updated" => (Time.now - 1.days).to_i,
            "categories" => [],
            "expires_at" => (Time.now + 2.hours).to_i,
            # Optional
            "url" => "http://www.myapp.com",
            "domain" => "myapp.com",
            "aspect_ratio" => 6.1045
          }
        ]
      end

      if !respond_with[:in_app_message].nil?
        modal_message = {
          "message" => "This is a modal in-app message from the stub API!",
          "duration" => 2000,
          "slide_from" => "TOP",
          "extras" => [{"my key" => "my value"}],
          "card_id" => "card_id of in-app message",
          "click_action" => "URI",
          "uri" => "http://google.com",
          "message_close" => "SWIPE",
          "type" => "MODAL",
          "image_url" => "http://i.imgur.com/K7HPBHF.gif",
          "header" => "This is my header"
        }
        full_message = {
          "message" => "This is a full-screen in-app message from the stub API!",
          "duration" => 2000,
          "slide_from" => "TOP",
          "extras" => [{"my key" => "my value"}],
          "card_id" => "card_id of in-app message",
          "click_action" => "URI",
          "uri" => "http://google.com",
          "message_close" => "SWIPE",
          "type" => "FULL",
          "image_url" => "http://i.imgur.com/tpK7ojq.gif",
          "btns" => [
            {"text" => "Goes to Google", "click_action" => "URI", "uri" => "http://google.com"},
            {"text" => "Does Nothing"}
          ]
        }
        basic_message = {
          "message" => "This is an in-app message from the stub API!",
          "duration" => 2000,
          "slide_from" => "TOP",
          "extras" => [{"my key" => "my value"}],
          "campaign_id" => "campaign_id of in-app message",
          "click_action" => "URI",
          "uri" => "http://google.com",
          "message_close" => "AUTO_DISMISS",
          "icon" => "\uf042",
          "icon_color" => 4294901760
        }

        in_app_messages = []

        if params[:api_key] == "modal"
          in_app_messages << modal_message
        elsif params[:api_key] == "full"
          in_app_messages << full_message
        elsif params[:api_key] == "array"
          in_app_messages << basic_message
          in_app_messages << modal_message
          in_app_messages << full_message
        else
          in_app_messages << basic_message
        end

        if respond_with[:in_app_message][:all].to_s != "true"
          in_app_messages = in_app_messages.slice(0, respond_with[:in_app_message][:count].to_i)
        end
        response_body[:in_app_message] = in_app_messages
      end

      if !respond_with[:config].nil?
        config = respond_with[:config]
        if config[:config_time].nil?
          halt_with_error("config_time not be nil", response_body)
        end

        logger.info("Received config request with a last config timestamp of #{config[:config_time]}")

        response_body[:config] = {
          "time" => Time.now.to_i,
          "events_blacklist" => ["blacklisted_event1", "blacklisted_event2"],
          "attributes_blacklist" => ["blacklisted_attribute1", "blacklisted_attribute2"],
          "purchases_blacklist" => ["blacklisted_purchase1", "blacklisted_purchase2"]
        }
      end
    end

    if params[:api_key].starts_with?("sleep_")
      sleep_time = params[:api_key][6..-1].to_i
      sleep sleep_time
    end

    response_body.to_json
  end
end
