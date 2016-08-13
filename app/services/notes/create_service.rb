module Notes
  class CreateService < BaseService
    def execute
      note = project.notes.new(params)
      note.author = current_user
      note.system = false

      if note.award_emoji?
        noteable = note.noteable
        todo_service.new_award_emoji(noteable, current_user)
        return noteable.create_award_emoji(note.award_emoji_name, current_user)
      end

      # We execute commands (extracted from `params[:note]`) on the noteable
      # **before** we save the note because if the note consists of commands
      # only, there is no need be create a note!
      slash_commands_service = SlashCommandsService.new(project, current_user)
      content, command_params = slash_commands_service.extract_commands(note)

      note.note = content

      if note.save
        # Finish the harder work in the background
        NewNoteWorker.perform_in(2.seconds, note.id, params)
        todo_service.new_note(note, current_user)
      end

      # We must add the error after we call #save because errors are reset
      # when #save is called
      if slash_commands_service.execute(command_params, note) && note.note.blank?
        note.errors.add(:commands_only, 'Your commands are being executed.')
      end

      note
    end
  end
end
