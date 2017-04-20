module Travis
  module Build
    class CompilationError < StandardError
      attr_accessor :doc_path
    end
  end
end
