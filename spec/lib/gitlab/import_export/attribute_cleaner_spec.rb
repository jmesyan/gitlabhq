require 'spec_helper'

describe Gitlab::ImportExport::AttributeCleaner do
  let(:relation_class) { double('relation_class').as_null_object }
  let(:unsafe_hash) do
    {
      'id' => 101,
      'service_id' => 99,
      'moved_to_id' => 99,
      'namespace_id' => 99,
      'ci_id' => 99,
      'random_project_id' => 99,
      'random_id' => 99,
      'milestone_id' => 99,
      'project_id' => 99,
      'user_id' => 99,
      'random_id_in_the_middle' => 99,
      'notid' => 99,
      'import_source' => 'whatever',
      'import_type' => 'whatever',
      'non_existent_attr' => 'whatever'
    }
  end

  let(:post_safe_hash) do
    {
      'project_id' => 99,
      'user_id' => 99,
      'random_id_in_the_middle' => 99,
      'notid' => 99
    }
  end

  let(:excluded_keys) { %w[import_source import_type] }

  subject { described_class.clean(relation_hash: unsafe_hash, relation_class: relation_class, excluded_keys: excluded_keys) }

  before do
    allow(relation_class).to receive(:attribute_method?).and_return(true)
    allow(relation_class).to receive(:attribute_method?).with('non_existent_attr').and_return(false)
  end

  it 'removes unwanted attributes from the hash' do
    expect(subject).to eq(post_safe_hash)
  end

  it 'removes attributes not present in relation_class' do
    expect(subject.keys).not_to include 'non_existent_attr'
  end

  it 'removes excluded keys from the hash' do
    expect(subject.keys).not_to include excluded_keys
  end

  it 'does not remove excluded key if not listed' do
    parsed_hash = described_class.clean(relation_hash: unsafe_hash, relation_class: relation_class)

    expect(parsed_hash.keys).to eq post_safe_hash.keys + excluded_keys
  end
end
