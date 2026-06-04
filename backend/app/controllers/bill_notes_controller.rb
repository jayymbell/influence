# frozen_string_literal: true

class BillNotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bill
  before_action :set_note, only: [:show, :update, :destroy, :share, :unshare, :pin, :unpin]

  # GET /bills/:bill_id/notes/:id
  def show
    authorize @note, :show?
    render_success(data: { note: note_data(@note) })
  end

  # GET /bills/:bill_id/notes
  def index
    authorize @bill, :show?
    notes = @bill.bill_notes.visible_to(current_user).includes(:user)
                 .order(pinned: :desc, created_at: :desc)
    render_success(data: { notes: notes.map { |n| note_data(n) } }, message: 'Notes found.')
  end

  # POST /bills/:bill_id/notes
  def create
    authorize @bill, :show?
    note = @bill.bill_notes.build(note_params.merge(user: current_user))
    if note.save
      render_success(data: { note: note_data(note) }, message: 'Note created.', status: :created)
    else
      render_error(errors: note.errors.full_messages, message: 'Could not create note.')
    end
  end

  # PATCH /bills/:bill_id/notes/:id
  def update
    authorize @note, :update?
    if @note.update(note_params)
      render_success(data: { note: note_data(@note) }, message: 'Note updated.')
    else
      render_error(errors: @note.errors.full_messages, message: 'Could not update note.')
    end
  end

  # DELETE /bills/:bill_id/notes/:id
  def destroy
    authorize @note, :destroy?
    @note.destroy
    render_success(message: 'Note deleted.')
  end

  # PATCH /bills/:bill_id/notes/:id/share
  def share
    authorize @note, :share?
    @note.update!(shared: true)
    render_success(data: { note: note_data(@note) }, message: 'Note shared.')
  end

  # PATCH /bills/:bill_id/notes/:id/unshare
  def unshare
    authorize @note, :unshare?
    @note.update!(shared: false, pinned: false)
    render_success(data: { note: note_data(@note) }, message: 'Note unshared.')
  end

  # PATCH /bills/:bill_id/notes/:id/pin
  def pin
    authorize @note, :pin?
    unless @note.shared?
      return render_error(errors: ['Note must be shared before it can be pinned.'], message: 'Cannot pin note.')
    end
    @note.update!(pinned: true)
    render_success(data: { note: note_data(@note) }, message: 'Note pinned.')
  end

  # PATCH /bills/:bill_id/notes/:id/unpin
  def unpin
    authorize @note, :pin?
    @note.update!(pinned: false)
    render_success(data: { note: note_data(@note) }, message: 'Note unpinned.')
  end

  private

  def set_bill
    @bill = Bill.find(params[:bill_id])
  end

  def set_note
    @note = @bill.bill_notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:title, :content)
  end

  def note_data(note)
    {
      id:         note.id,
      title:      note.title,
      content:    note.content,
      shared:     note.shared,
      pinned:     note.pinned,
      author:     note.user.person&.display_name || note.user.email,
      author_id:  note.user_id,
      created_at: note.created_at,
      updated_at: note.updated_at,
    }
  end
end
