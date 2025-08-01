module WorkflowsControllerPatch
  def self.included(base)
    base.class_eval do
      # 기존 edit 메서드에 시각화 지원만 추가
      alias_method :edit_without_viz, :edit
      
      def edit
        # 기존 edit 로직 실행
        edit_without_viz
        
        # 시각화를 위한 최소한의 변수 확인
        # 기존 Redmine 로직이 이미 @roles, @trackers, @statuses를 설정했을 것임
        Rails.logger.info "Workflow Viz: @roles=#{@roles&.count}, @trackers=#{@trackers&.count}, @statuses=#{@statuses&.count}"
        Rails.logger.info "Workflow Viz: @role=#{@role&.name}, @tracker=#{@tracker&.name}"
      end
    end
  end
end

# Rails 애플리케이션 로드 후 패치 적용
Rails.application.config.to_prepare do
  unless WorkflowsController.included_modules.include?(WorkflowsControllerPatch)
    WorkflowsController.include(WorkflowsControllerPatch)
  end
end
