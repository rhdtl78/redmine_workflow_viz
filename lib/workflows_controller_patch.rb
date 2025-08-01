module WorkflowsControllerPatch
  def self.included(base)
    base.class_eval do
      # 기존 edit 메서드를 prepend로 확장
      prepend InstanceMethods
    end
  end

  module InstanceMethods
    def edit
      # 기존 edit 로직 실행
      super
      
      # 워크플로우 시각화를 위한 추가 로직
      ensure_workflow_variables
    end
    
    private
    
    def ensure_workflow_variables
      # roles와 trackers가 없으면 기본값 설정
      @roles ||= Role.givable.sorted
      @trackers ||= Tracker.sorted
      
      # 파라미터에서 role과 tracker 설정
      if params[:role_id].present? && @role.nil?
        @role = Role.find_by(id: params[:role_id])
      end
      
      if params[:tracker_id].present? && @tracker.nil?
        @tracker = Tracker.find_by(id: params[:tracker_id])
      end
      
      # 상태 정보 설정
      if @statuses.nil? && @tracker
        if params[:used_statuses_only] == '1'
          @statuses = @tracker.issue_statuses.where(id: WorkflowTransition.where(tracker_id: @tracker.id).select(:old_status_id).distinct)
        else
          @statuses = @tracker.issue_statuses
        end
      end
      
      # 기본값 설정
      @statuses ||= []
      @used_statuses_only = params[:used_statuses_only] == '1'
    end
  end
end

# Rails 애플리케이션 로드 후 패치 적용
Rails.application.config.to_prepare do
  unless WorkflowsController.included_modules.include?(WorkflowsControllerPatch)
    WorkflowsController.include(WorkflowsControllerPatch)
  end
end
