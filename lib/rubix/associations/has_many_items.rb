module Rubix
  module Associations
    module HasManyItems
      def self.included(base)
        raise AssociationError.new("base(%s) must be a subclass of Rubix::Model" % base) unless base.superclass == Rubix::Model
      end
      
      def items= is
        return unless is
        @items    = is
        @item_ids = is.map(&:id)
      end
      
      def items
        return @items if @items
        return unless @item_ids
        @items = @item_ids.map { |iid| Item.find(:id => iid, :host_id => id) }
      end

      def item_ids= iids
        return unless iids
        @item_ids = iids
      end
      
      def item_ids
        return @item_ids if @item_ids
        return unless @items
        @item_ids = @items.map(&:id)
      end
      
    end
  end
end
