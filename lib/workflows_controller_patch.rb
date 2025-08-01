Rails.logger.info "=== Loading WorkflowsControllerPatch ==="

module WorkflowsControllerPatch
  def self.included(base)
    Rails.logger.info "=== WorkflowsControllerPatch included in #{base} ==="
    
    base.class_eval do
      alias_method :edit_without_viz, :edit
      
      def edit
        Rails.logger.info "=== WorkflowsController#edit called with patch ==="
        Rails.logger.info "Params: #{params.inspect}"
        
        # 기존 edit 로직 실행
        result = edit_without_viz
        
        Rails.logger.info "After edit_without_viz - @roles: #{@roles&.count}, @trackers: #{@trackers&.count}"
        
        # 시각화를 위한 변수 설정
        if params[:role_id].present? && params[:tracker_id].present?
          role_id = params[:role_id].is_a?(Array) ? params[:role_id].first : params[:role_id]
          tracker_id = params[:tracker_id].is_a?(Array) ? params[:tracker_id].first : params[:tracker_id]
          
          @workflow_viz_role = Role.find_by(id: role_id)
          @workflow_viz_tracker = Tracker.find_by(id: tracker_id)
          
          Rails.logger.info "Set viz variables - role: #{@workflow_viz_role&.name}, tracker: #{@workflow_viz_tracker&.name}"
        end
        
        # 강제로 뷰에 HTML 추가
        @workflow_viz_debug = <<-HTML.html_safe
        <div style="margin-top: 20px; padding: 15px; border: 3px solid #28a745; border-radius: 4px; background-color: #e6ffe6;">
          <h3>✅ Controller Patch Working!</h3>
          <p>This message is added by the controller patch.</p>
          <p>Params: role_id=#{params[:role_id].inspect}, tracker_id=#{params[:tracker_id].inspect}</p>
          <p>Time: #{Time.current}</p>
        </div>
        HTML
        
        result
      end
    end
  end
end

# 컨트롤러 패치 적용
Rails.application.config.to_prepare do
  Rails.logger.info "=== Applying WorkflowsControllerPatch ==="
  
  unless WorkflowsController.included_modules.include?(WorkflowsControllerPatch)
    WorkflowsController.include(WorkflowsControllerPatch)
    Rails.logger.info "✓ WorkflowsControllerPatch applied successfully"
  else
    Rails.logger.info "⚠ WorkflowsControllerPatch already applied"
  end
end

Rails.logger.info "=== WorkflowsControllerPatch loaded ==="
