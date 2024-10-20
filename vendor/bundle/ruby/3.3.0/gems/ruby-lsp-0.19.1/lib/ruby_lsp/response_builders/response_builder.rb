# typed: strict


module RubyLsp
  module ResponseBuilders
    class ResponseBuilder
      extend T::Sig
      extend T::Generic

      abstract!

      sig { abstract.returns(T.anything) }
      def response; end
    end
  end
end
