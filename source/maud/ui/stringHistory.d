module maud.ui.stringHistory;

class StringHistory
{
	dstring[] story;
	size_t p_index;
	size_t r_index;
	this(size_t size = 20)
	{
		story = new dstring[size];
		r_index = 0;
		p_index = 0;
	}
	dstring peek(){
		return story[r_index] is null? ""d : story[r_index];
	}

	dstring pop(){
		r_index = (story.length + --r_index) % story.length;
		return story[r_index] is null? ""d : story[r_index];
	}

	dstring dePop(){
		r_index = ++r_index % story.length;
		return story[r_index] is null? ""d : story[r_index];
	}

	void rewind(){
		r_index = p_index;
	}

	void push(dstring x){
		if(x != ""d){
			story[p_index] = x;
			p_index = (++p_index) % story.length;
		}
	}
}

