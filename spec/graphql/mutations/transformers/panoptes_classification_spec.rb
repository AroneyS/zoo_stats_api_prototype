Rspec.describe Transformers::PanoptesClassification do
  subject(:panoptes_classification_transformer) { Transformers::PanoptesClassification }
  let(:payload) do
    {
      "source" => "panoptes",
      "type" => "classification",
      "version" => "1.0.0",
      "timestamp" => "2016-10-10T12:59:48Z",
      "data" => {
        "id" => "18521902",
        "created_at" => "2016-10-10T12:59:48.233Z",
        "updated_at" => "2016-10-10T12:59:48.293Z",
        "user_ip" => "127.0.0.1",
        "workflow_version" => "2.5",
        "gold_standard" =>  nil,
        "expert_classifier" =>  nil,
        "annotations" => [
            {
              "task" => "init",
              "value" => 1
            }
        ],
        "metadata" => {
            "session" => "8c09ed53c6ee1b397d9ae6b6d1eef096a2c966debdc13678d2b151c8c82c3c8c",
            "viewport" => {
              "width" => 1440,
              "height" => 661
            },
            "started_at" => "2016-10-10T12:59:44.812Z",
            "user_agent" => "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:49.0) Gecko/20100101 Firefox/49.0",
            "utc_offset" => "0",
            "finished_at" => "2016-10-10T12:59:46.795Z",
            "live_project" => true,
            "user_language" => "en",
            "user_group_ids" => [

            ],
            "subject_dimensions" => [
              {
                  "clientWidth" => 480,
                  "clientHeight" => 480,
                  "naturalWidth" => 480,
                  "naturalHeight" => 480
              }
            ],
            "workflow_version" => "2.5"
        },
        "href" => "/classifications/18521902",
        "links" => {
            "project" => "764",
            "user" => "1",
            "workflow" => "2303",
            "workflow_content" => "2302",
            "subjects" => ["3069945"]
        }
      },
      "linked" => {
        "projects" => [
            {
              "id" => "764",
              "display_name" => "Pulsar Hunters",
              "created_at" => "2015-08-31T09:51:30.913Z",
              "href" => "/projects/764"
            }
        ],
        "users" => [
            {
              "id" => "1",
              "login" => "Zookeeper",
              "href" => "/users/1"
            }
        ],
        "workflows" => [
            {
              "id" => "2303",
              "display_name" => "Bluedot LOTAAS",
              "created_at" => "2016-07-22T16:47:46.489Z",
              "href" => "/workflows/2303"
            }
        ],
        "workflow_contents" => [
            {
              "id" => "2302",
              "created_at" => "2016-07-22T16:47:46.493Z",
              "updated_at" => "2016-07-22T18:03:04.964Z",
              "href" => "/workflow_contents/2302"
            }
        ],
        "subjects" => [
            {
              "id" => "3069945",
              "locations" => [
                {
                  "image/jpeg" => "https://panoptes-uploads.zooniverse.org/production/subject_location/5efcf7a2-2a6d-410b-afdf-0913552e5d18.jpeg"
                }
              ],
              "metadata" => {
                  "DM" => "35.48",
                  "S/N" => "4.4",
                  "Period" => "15.98"
              },
              "created_at" => "2016-07-22T16:51:33.679Z",
              "updated_at" => "2016-07-22T16:51:33.679Z",
              "href" => "/subjects/3069945"
            }
        ]
      }
    }
  end

  let(:expected_data) do
    # TODO: do we want to store the metadata or the diff of the data minus what we have?
    # attributes.data - attributes already in payload
    expected_data = payload["data"]
    #expected_data.except!("id")
    #expected_data["metadata"].except!("finished_at")
    #expected_data["links"].except!("project", "workflow", "user")
  end
  let(:expected_session_time) { 2.0 }

  let(:expected_result) do 
    {
      event_id:        payload.dig("data", "id"),
      event_type:      payload.dig("type"),
      event_source:    payload.dig("source"),
      event_time:      DateTime.parse(payload.dig("data", "metadata", "finished_at")),
      project_id:      payload.dig("data", "links", "project"),
      workflow_id:     payload.dig("data", "links", "workflow"),
      user_id:         payload.dig("data", "links", "user"),
      data:            expected_data,
      session_time:    expected_session_time
    }
  end

  it 'returns a hash with expected data' do
    transformed_payload = panoptes_classification_transformer.new(payload).transform
    expect(transformed_payload.keys).to eq(expected_result.keys)

    transformed_payload.each do |k|
      expect(transformed_payload[k]).to eq(expected_result[k])
    end
    
    expect(transformed_payload[:data].keys).to eq(expected_result[:data].keys)
  end
end


def event_data(attribute)
  event.dig("data",attribute)
end

def link_data(link)
  event_data("links").dig(link)
end

def test_id
  assert_equal(event_data("id"), panoptes_classification.id)
end

def test_timestamp
  expected = DateTime.parse(event_data("updated_at"))
  assert_equal(expected, panoptes_classification.timestamp)
end

def test_attributes
  expected = {
    classification_id: event_data("id"),
    project_id: link_data("project"),
    workflow_id: link_data("workflow"),
    user_id: link_data("user"),
    subject_ids: link_data("subjects"),
    subject_urls: event.dig("linked", "subjects", 0, "locations"),
    geo: {}
  }
  assert_equal(expected, panoptes_classification.attributes)
end