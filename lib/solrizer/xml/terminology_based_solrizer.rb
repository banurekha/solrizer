# This module is only suitable to mix into Classes that use the OM::XML::Document Module
module Solrizer::XML::TerminologyBasedSolrizer
  
  def self.default_field_mapper
    @@default_field_mapper ||= Solrizer::FieldMapper::Default.new
  end
  
  # Module Methods
  
  # Build a solr document from +doc+ based on its terminology
  # @doc  OM::XML::Document
  # @solr_doc (optional) Solr::Document to populate
  def self.solrize(doc, solr_doc=Solr::Document.new, field_mapper = nil)
    unless doc.class.terminology.nil?
      doc.class.terminology.terms.each_pair do |term_name,term|
        doc.solrize_term(term, solr_doc, field_mapper)
        # self.solrize_by_term(accessor_name, accessor_info, :solr_doc=>solr_doc)
      end
    end

    return solr_doc
  end
  
  # Populate a solr document with fields based on nodes in +xml+ corresponding to the 
  # term identified by +term_pointer+ within +terminology+
  # @doc OM::XML::Document or Nokogiri::XML::Node
  # @term_pointer Array pointing to the desired term in +terminology+  
  def self.solrize_term(doc, term, solr_doc = Solr::Document.new, field_mapper = nil, opts={})
    terminology = doc.class.terminology
    parents = opts.fetch(:parents, [])

    term_pointer = parents+[term.name]
  
    # term = terminology.retrieve_term(term_pointer)

    # prep children hash
    # child_accessors = accessor_info.fetch(:children, {})
    # xpath = term.xpath_for(*term_pointer)
    nodeset = doc.find_by_terms(*term_pointer)
    
    nodeset.each do |node|
      # create solr fields
      
      self.solrize_node(node, doc, term_pointer, term, solr_doc, field_mapper)
      term.children.each_pair do |child_term_name, child_term|
        doc.solrize_term(child_term, solr_doc, field_mapper, opts={:parents=>parents+[{term.name=>nodeset.index(node)}]})
        # self.solrize_term(doc, child_term_name, child_term, opts={:solr_doc=>solr_doc, :parents=>parents+[{accessor_name=>nodeset.index(node)}] })
      end
    end
    solr_doc
  end
  
  # Populate a solr document with solr fields corresponding to the given xml node
  # Field names are generated using settings from the term in the +doc+'s terminology corresponding to +term_pointer+
  # @doc OM::XML::Document or Nokogiri::XML::Node
  # @term_pointer Array pointing to the desired term in +terminology+
  # @solr_doc (optional) Solr::Document to populate
  def self.solrize_node(node, doc, term_pointer, term, solr_doc = Solr::Document.new, field_mapper = nil, opts = {})
    field_mapper ||= self.default_field_mapper
    terminology = doc.class.terminology
    # term = terminology.retrieve_term(*term_pointer)
    
    if term.path.kind_of?(Hash) && term.path.has_key?(:attribute)
      node_value = node.value
    else
      node_value = node.text
    end
    
    generic_field_name_base = OM::XML::Terminology.term_generic_name(*term_pointer)
    
    field_mapper.solr_names_and_values(generic_field_name_base, node_value, term.data_type, term.index_as).each do |field_name, field_value|
      solr_doc << Solr::Field.new(field_name => field_value)
    end
    
    if term_pointer.length > 1
      hierarchical_field_name_base = OM::XML::Terminology.term_hierarchical_name(*term_pointer)
      field_mapper.solr_names_and_values(hierarchical_field_name_base, node_value, term.data_type, term.index_as).each do |field_name, field_value|
        solr_doc << Solr::Field.new(field_name => field_value)
      end
    end
    solr_doc
  end
  
  # Instance Methods
  
  attr_accessor :field_mapper
  
  def to_solr(solr_doc = Solr::Document.new, field_mapper = self.field_mapper) # :nodoc:
    Solrizer::XML::TerminologyBasedSolrizer.solrize(self, solr_doc, field_mapper)
  end
  
  def solrize_term(term, solr_doc = Solr::Document.new, field_mapper = self.field_mapper, opts={})
    Solrizer::XML::TerminologyBasedSolrizer.solrize_term(self, term, solr_doc, field_mapper, opts)    
  end
  
  def solrize_node(node, term_pointer, term, solr_doc = Solr::Document.new, field_mapper = self.field_mapper, opts={})
    Solrizer::XML::TerminologyBasedSolrizer.solrize_node(node, self, term_pointer, solr_doc, field_mapper, opts)
  end
  
end
